const crypto = require('crypto');
const { createClient } = require('@supabase/supabase-js');
const { Resend } = require('resend');

// Initialize Supabase Client with service role key for bypassing RLS on admin updates
// Note: We use SUPABASE_SERVICE_ROLE_KEY to safely write updates server-side.
// These variables must be configured in Vercel environment settings.
const supabaseUrl = process.env.SUPABASE_URL || 'https://nhrpqizxxqiiknwaaxlp.supabase.co';
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

// Webhook Secret and API key
const webhookSecret = 'whsec_91dc93d3688833449e59292e259dca30';
const rushPayApiKey = 'rp_e67014a3fd936ceba21a9ffe46a6399f';

// Initialize Resend
const resendApiKey = process.env.RESEND_API_KEY;
const resend = resendApiKey ? new Resend(resendApiKey) : null;

// Collect raw body buffer for signature calculation
async function getRawBody(req) {
  const chunks = [];
  for await (const chunk of req) {
    chunks.push(typeof chunk === 'string' ? Buffer.from(chunk) : chunk);
  }
  return Buffer.concat(chunks);
}

module.exports = async function handler(req, res) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  try {
    const rawBodyBuffer = await getRawBody(req);
    const rawBody = rawBodyBuffer.toString('utf8');

    // Parse payload safely
    let payload;
    try {
      payload = JSON.parse(rawBody);
    } catch (parseErr) {
      return res.status(400).json({ error: 'Invalid JSON payload' });
    }

    console.log('Received RushPay Webhook:', payload);

    // Verify webhook signature
    const signatureHeader = req.headers['x-rushpay-signature'] || req.headers['x-signature'] || req.headers['signature'];
    let signatureVerified = false;

    if (signatureHeader) {
      const computedSignature = crypto
        .createHmac('sha256', webhookSecret)
        .update(rawBody)
        .digest('hex');

      if (crypto.timingSafeEqual(Buffer.from(computedSignature, 'hex'), Buffer.from(signatureHeader, 'hex'))) {
        signatureVerified = true;
        console.log('Webhook signature successfully verified.');
      } else {
        console.warn('Webhook signature mismatch.');
      }
    } else {
      console.warn('Webhook signature header missing.');
    }

    // Reconcile status directly from RushPay API (source of truth)
    const paymentRef = payload.payment_reference || (payload.data && payload.data.payment_reference) || payload.reference;
    if (!paymentRef) {
      return res.status(400).json({ error: 'Missing payment reference' });
    }

    console.log('Reconciling payment status for ref:', paymentRef);
    const statusRes = await fetch(`https://core.rushpay.cash/api/v1/merchant/payments/status?payment_reference=${paymentRef}`, {
      method: 'GET',
      headers: {
        'X-API-Key': rushPayApiKey,
      },
    });

    if (!statusRes.ok) {
      const errText = await statusRes.text();
      console.error('Failed to query RushPay status:', errText);
      return res.status(500).json({ error: 'Failed to reconcile payment status from RushPay API' });
    }

    const statusData = await statusRes.json();
    console.log('RushPay status check result:', statusData);

    if (statusData.success !== true || !statusData.data) {
      return res.status(400).json({ error: 'Invalid payment reference details returned' });
    }

    const paymentStatus = statusData.data.status;
    const paymentAmount = statusData.data.amount;
    const paymentMetadata = statusData.data.metadata || {};
    const customerEmail = statusData.data.customer_email || paymentMetadata.email;

    // Verify payment is indeed successful
    // Status can be: 'completed', 'paid', 'successful', 'success' depending on provider mappings.
    const isPaid = ['completed', 'paid', 'successful', 'success'].includes(paymentStatus.toLowerCase());
    
    if (!isPaid) {
      console.log(`Payment status is ${paymentStatus}. No subscription upgrade applied.`);
      return res.status(200).json({ success: true, message: `Payment is pending or failed (status: ${paymentStatus})` });
    }

    // Upgrade subscription tier
    const userId = paymentMetadata.user_id;
    const tier = paymentMetadata.tier; // 'BASIC' or 'PRO'

    if (!userId || !tier) {
      console.error('Missing user_id or tier in payment metadata:', paymentMetadata);
      return res.status(400).json({ error: 'Missing user_id or tier metadata' });
    }

    if (!['BASIC', 'PRO'].includes(tier.toUpperCase())) {
      return res.status(400).json({ error: 'Invalid subscription tier specified' });
    }

    // Calculate credits to award
    const creditsToAward = tier.toUpperCase() === 'PRO' ? 10.0000 : 5.0000;

    console.log(`Upgrading user ${userId} to ${tier} tier. Awarding $${creditsToAward} credits.`);

    // Connect to Supabase
    if (!supabaseServiceKey) {
      console.error('SUPABASE_SERVICE_ROLE_KEY is not defined in environment.');
      return res.status(500).json({ error: 'Backend server configuration error' });
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);
    const resetDate = new Date();
    resetDate.setMonth(resetDate.getMonth() + 1);

    const { error: dbError } = await supabase
      .from('user_subscriptions')
      .upsert({
        id: userId,
        tier: tier.toUpperCase(),
        credits: creditsToAward,
        subscription_reset_at: resetDate.toISOString(),
        updated_at: new Date().toISOString(),
      });

    if (dbError) {
      console.error('Database update failed:', dbError);
      return res.status(500).json({ error: 'Database update failed: ' + dbError.message });
    }

    console.log('Database tier update succeeded.');

    // Send transactional receipt email via Resend
    if (resend && customerEmail) {
      try {
        console.log('Sending receipt email to:', customerEmail);
        const emailHtml = `
          <!DOCTYPE html>
          <html>
          <head>
            <meta charset="utf-8">
            <title>Tech4All AI Receipt</title>
          </head>
          <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background-color: #0e0a08; color: #ffffff; padding: 40px; margin: 0;">
            <div style="max-width: 500px; margin: 0 auto; background-color: #1c1410; border-radius: 20px; border: 1px solid #2d241d; padding: 32px; box-shadow: 0 10px 30px rgba(0,0,0,0.5);">
              <div style="text-align: center; margin-bottom: 24px;">
                <span style="background-color: #f27f0d; color: #ffffff; font-weight: bold; font-size: 24px; padding: 10px 16px; border-radius: 12px; display: inline-block;">T</span>
                <h2 style="color: #ffffff; margin-top: 16px; font-weight: 800;">Payment Successful</h2>
                <p style="color: #9ca3af; font-size: 14px;">Thank you for upgrading your Tech4All account!</p>
              </div>
              
              <div style="border-top: 1px solid #2d241d; border-bottom: 1px solid #2d241d; padding: 20px 0; margin: 24px 0;">
                <table style="width: 100%; font-size: 14px; border-collapse: collapse;">
                  <tr style="height: 32px;">
                    <td style="color: #9ca3af;">Subscription Plan</td>
                    <td style="text-align: right; font-weight: bold; color: #ffffff;">${tier.toUpperCase()} Plan</td>
                  </tr>
                  <tr style="height: 32px;">
                    <td style="color: #9ca3af;">Amount Paid</td>
                    <td style="text-align: right; font-weight: bold; color: #ffffff;">${paymentAmount} GHS</td>
                  </tr>
                  <tr style="height: 32px;">
                    <td style="color: #9ca3af;">Credits Allocated</td>
                    <td style="text-align: right; font-weight: bold; color: #10b981;">$${creditsToAward.toFixed(2)} USD</td>
                  </tr>
                  <tr style="height: 32px;">
                    <td style="color: #9ca3af;">Payment Reference</td>
                    <td style="text-align: right; font-family: monospace; color: #9ca3af; font-size: 12px;">${paymentRef}</td>
                  </tr>
                </table>
              </div>
              
              <p style="color: #9ca3af; font-size: 13px; line-height: 1.6; text-align: center;">
                Your premium limits and credits are now active! Simply refresh your app to start using Sonder 0.1 Pro models and high-quality image generation.
              </p>
              
              <div style="text-align: center; margin-top: 32px; font-size: 11px; color: #4b5563;">
                &copy; ${new Date().getFullYear()} Tech4All AI. Powered by RushPay.
              </div>
            </div>
          </body>
          </html>
        `;

        await resend.emails.send({
          from: 'Tech4All AI <noreply@techhubafrica.org>',
          to: customerEmail,
          subject: `Tech4All AI - ${tier.toUpperCase()} Subscription Payment Receipt`,
          html: emailHtml,
        });
        console.log('Receipt email sent successfully.');
      } catch (emailErr) {
        console.error('Error sending receipt email:', emailErr);
      }
    } else {
      console.warn('Resend client not initialized or customer email missing. Skipping email receipt.');
    }

    return res.status(200).json({ success: true, message: 'Webhook processed successfully' });
  } catch (err) {
    console.error('Webhook handler error:', err);
    return res.status(500).json({ error: 'Internal Server Error' });
  }
};

// Export Vercel serverless function configuration to collect raw body
module.exports.config = {
  api: {
    bodyParser: false,
  },
};
