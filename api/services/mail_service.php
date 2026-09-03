<?php
// api/services/mail_service.php

require_once dirname(__DIR__) . '/config/database.php';
require_once dirname(__DIR__) . '/config/env.php';

class MailService {
    public static function generateAndSendOtp($email, $userName = 'Tapper') {
        $db = Database::getConnection();

        // 1. Invalidate previous unexpired OTPs for this email
        $stmt = $db->prepare("UPDATE otps SET is_used = 1 WHERE email = :email");
        $stmt->execute([':email' => $email]);

        // 2. Generate 6-digit numeric code
        $otpCode = strval(random_int(100000, 999999));
        $expiryMinutes = (int)Env::get('OTP_EXPIRY_MINUTES', 10);
        $expiresAt = date('Y-m-d H:i:s', strtotime("+$expiryMinutes minutes"));

        // 3. Store in database
        $insert = $db->prepare("
            INSERT INTO otps (email, otp_code, expires_at, is_used)
            VALUES (:email, :code, :expires, 0)
        ");
        $insert->execute([
            ':email'   => $email,
            ':code'    => $otpCode,
            ':expires' => $expiresAt,
        ]);

        // 4. Send Email via PHP mail()
        $fromName = Env::get('MAIL_FROM_NAME', 'TapX Security');
        $fromEmail = Env::get('MAIL_FROM_EMAIL', 'noreply@tapx.ashiik.com');
        $subject = "Your TapX Verification Code: $otpCode";

        $htmlBody = "
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset='utf-8'>
            <style>
                body { background-color: #000000; color: #FFFFFF; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 24px; }
                .container { max-width: 500px; margin: 0 auto; background: #111111; border: 1px solid #27272A; border-radius: 20px; padding: 32px; text-align: center; }
                .logo { font-size: 28px; font-weight: 900; letter-spacing: 4px; color: #FFFFFF; margin-bottom: 8px; }
                .tagline { font-size: 11px; letter-spacing: 2px; color: #71717A; margin-bottom: 28px; }
                .code-box { background: #1A1A1E; border: 1.5px solid #FFFFFF; border-radius: 14px; padding: 18px 24px; font-size: 36px; font-weight: 800; letter-spacing: 8px; color: #FFFFFF; display: inline-block; margin: 20px 0; }
                .info { font-size: 14px; color: #A1A1AA; line-height: 1.6; }
                .footer { font-size: 11px; color: #52525B; margin-top: 30px; }
            </style>
        </head>
        <body>
            <div class='container'>
                <div class='logo'>TAPX</div>
                <div class='tagline'>TAP &bull; EARN &bull; COMPETE</div>
                <p class='info'>Hello <strong>" . htmlspecialchars($userName) . "</strong>,</p>
                <p class='info'>Use the verification code below to activate your TapX account:</p>
                <div class='code-box'>$otpCode</div>
                <p class='info'>This code will expire in $expiryMinutes minutes. If you did not request this, please ignore this email.</p>
                <div class='footer'>&copy; " . date('Y') . " TapX Network. All rights reserved.</div>
            </div>
        </body>
        </html>
        ";

        $headers = [
            "MIME-Version: 1.0",
            "Content-type: text/html; charset=UTF-8",
            "From: $fromName <$fromEmail>",
            "Reply-To: $fromEmail",
            "X-Mailer: PHP/" . phpversion(),
        ];

        $mailSent = @mail($email, $subject, $htmlBody, implode("\r\n", $headers));

        // Write to debug log
        $logDir = dirname(__DIR__) . '/logs';
        if (!is_dir($logDir)) {
            @mkdir($logDir, 0755, true);
        }
        $logFile = $logDir . '/otp_debug.log';
        $logEntry = "[" . date('Y-m-d H:i:s') . "] Email: $email | Code: $otpCode | Sent: " . ($mailSent ? 'YES' : 'NO') . "\n";
        @file_put_contents($logFile, $logEntry, FILE_APPEND);

        return [
            'sent' => $mailSent,
            'otp_code' => $otpCode,
            'expires_at' => $expiresAt,
        ];
    }

    public static function verifyOtp($email, $code) {
        $db = Database::getConnection();

        $stmt = $db->prepare("
            SELECT * FROM otps
            WHERE email = :email AND otp_code = :code AND is_used = 0 AND expires_at > NOW()
            ORDER BY id DESC LIMIT 1
        ");
        $stmt->execute([':email' => $email, ':code' => $code]);
        $record = $stmt->fetch();

        if (!$record) {
            return false;
        }

        $update = $db->prepare("UPDATE otps SET is_used = 1 WHERE id = :id");
        $update->execute([':id' => $record['id']]);

        return true;
    }

    // Send Real Payout Confirmation Email to User
    public static function sendPayoutConfirmationEmail($email, $userName, $amount, $currency, $method, $destination, $txId) {
        $fromName = Env::get('MAIL_FROM_NAME', 'TapX Financial');
        $fromEmail = Env::get('MAIL_FROM_EMAIL', 'noreply@tapx.ashiik.com');
        $currencySymbol = strtoupper($currency) === 'BDT' ? '৳' : '$';
        $formattedAmount = $currencySymbol . number_format($amount, 2);

        $subject = "Payout Completed: $formattedAmount sent via $method [$txId]";

        $htmlBody = "
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset='utf-8'>
            <style>
                body { background-color: #000000; color: #FFFFFF; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 24px; }
                .container { max-width: 520px; margin: 0 auto; background: #111111; border: 1px solid #27272A; border-radius: 20px; padding: 32px; text-align: center; }
                .logo { font-size: 28px; font-weight: 900; letter-spacing: 4px; color: #FFFFFF; margin-bottom: 6px; }
                .status-badge { display: inline-block; background: #22C55E15; border: 1px solid #22C55E; color: #22C55E; border-radius: 20px; padding: 6px 16px; font-size: 12px; font-weight: 700; text-transform: uppercase; margin-bottom: 20px; }
                .amount-card { background: #18181B; border: 1px solid #3F3F46; border-radius: 16px; padding: 20px; margin: 20px 0; }
                .amount { font-size: 34px; font-weight: 900; color: #FFFFFF; }
                .details-table { width: 100%; text-align: left; font-size: 13px; color: #A1A1AA; border-collapse: collapse; margin-top: 16px; }
                .details-table td { padding: 8px 0; border-bottom: 1px solid #27272A; }
                .details-table td:last-child { text-align: right; color: #FFFFFF; font-weight: 600; }
                .info { font-size: 13px; color: #71717A; line-height: 1.6; margin-top: 20px; }
                .footer { font-size: 11px; color: #52525B; margin-top: 28px; }
            </style>
        </head>
        <body>
            <div class='container'>
                <div class='logo'>TAPX</div>
                <div class='status-badge'>&bull; Payout Completed</div>
                <p style='font-size: 16px; color: #E4E4E7;'>Hello <strong>" . htmlspecialchars($userName) . "</strong>,</p>
                <p style='font-size: 14px; color: #A1A1AA;'>Your withdrawal request has been verified and processed successfully!</p>
                
                <div class='amount-card'>
                    <div style='font-size: 12px; color: #71717A; letter-spacing: 1px;'>AMOUNT DISBURSED</div>
                    <div class='amount'>$formattedAmount</div>
                    
                    <table class='details-table'>
                        <tr><td>Payment Method</td><td>" . htmlspecialchars($method) . "</td></tr>
                        <tr><td>Recipient Account</td><td>" . htmlspecialchars($destination) . "</td></tr>
                        <tr><td>Transaction ID</td><td>$txId</td></tr>
                        <tr><td>Status</td><td style='color: #22C55E;'>Completed</td></tr>
                    </table>
                </div>

                <p class='info'>The funds have been transferred directly to your $method account. Thank you for being a part of the TapX community!</p>
                <div class='footer'>&copy; " . date('Y') . " TapX Network. All rights reserved.</div>
            </div>
        </body>
        </html>
        ";

        $headers = [
            "MIME-Version: 1.0",
            "Content-type: text/html; charset=UTF-8",
            "From: $fromName <$fromEmail>",
            "Reply-To: $fromEmail",
            "X-Mailer: PHP/" . phpversion(),
        ];

        $mailSent = @mail($email, $subject, $htmlBody, implode("\r\n", $headers));

        // Write to log
        $logDir = dirname(__DIR__) . '/logs';
        if (!is_dir($logDir)) {
            @mkdir($logDir, 0755, true);
        }
        $logFile = $logDir . '/payout_emails.log';
        $logEntry = "[" . date('Y-m-d H:i:s') . "] Payout Sent: $email | Amount: $formattedAmount ($method) | Tx: $txId | Mail: " . ($mailSent ? 'SENT' : 'LOGGED') . "\n";
        @file_put_contents($logFile, $logEntry, FILE_APPEND);

        return $mailSent;
    }
}
