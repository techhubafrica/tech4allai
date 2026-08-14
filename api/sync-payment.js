const { createClient } = require('@supabase/supabase-js');
const { Resend } = require('resend');

const supabaseUrl = process.env.SUPABASE_URL || 'https://nhrpqizxxqiiknwaaxlp.supabase.co';
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const rushPayApiKey = 'rp_e67014a3fd936ceba21a9ffe46a6399f';

const resendApiKey = process.env.RESEND_API_KEY;
const resend = resendApiKey ? new Resend(resendApiKey) : null;

module.exports = async function handler(req, res) {
  // Enable CORS
  res.setHeader('Access-Control-Allow-Credentials', 'true');
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader('Access-Control-Allow-Headers', 'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  const paymentRef = req.query.payment_reference || (req.body && req.body.payment_reference);
  if (!paymentRef) {
    return res.status(400).json({ error: 'Missing payment_reference parameter' });
  }

  try {
    // 1. Check status from RushPay API
    const statusRes = await fetch(`https://core.rushpay.cash/api/v1/merchant/payments/status?payment_reference=${paymentRef}`, {
      method: 'GET',
      headers: {
        'X-API-Key': rushPayApiKey,
      },
    });

    if (!statusRes.ok) {
      const errText = await statusRes.text();
      return res.status(500).json({ error: 'RushPay status query failed: ' + errText });
    }

    const statusData = await statusRes.json();
    if (!statusData.success || !statusData.data) {
      return res.status(400).json({ error: 'Invalid response from RushPay' });
    }

    const paymentStatus = (statusData.data.status || statusData.data.payment_status || '').toLowerCase();
    const isPaid = statusData.data.paid === true || 
                   statusData.data.verified === true ||
                   ['completed', 'paid', 'successful', 'success'].includes(paymentStatus);

    if (!isPaid) {
      return res.status(200).json({
        success: false,
        is_paid: false,
        status: paymentStatus,
        message: `Payment status is ${paymentStatus}. Not yet completed.`,
      });
    }

    // 2. Connect to Supabase
    if (!supabaseServiceKey) {
      return res.status(500).json({ error: 'SUPABASE_SERVICE_ROLE_KEY missing on server' });
    }
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // 3. Resolve user and tier from pending_payments
    const { data: pendingData, error: pendingError } = await supabase
      .from('pending_payments')
      .select('user_id, tier, status')
      .eq('payment_reference', paymentRef)
      .maybeSingle();

    if (pendingError || !pendingData) {
      return res.status(404).json({ error: 'Transaction reference not found in pending_payments' });
    }

    const userId = pendingData.user_id;
    const tier = (pendingData.tier || 'BASIC').toUpperCase();
    const creditsToAward = tier === 'PRO' ? 10.0000 : 5.0000;

    const resetDate = new Date();
    resetDate.setMonth(resetDate.getMonth() + 1);

    // 4. Upgrade user in user_subscriptions
    const { error: dbError } = await supabase
      .from('user_subscriptions')
      .upsert({
        id: userId,
        tier: tier,
        credits: creditsToAward,
        subscription_reset_at: resetDate.toISOString(),
        updated_at: new Date().toISOString(),
      });

    if (dbError) {
      return res.status(500).json({ error: 'Supabase update failed: ' + dbError.message });
    }

    // 5. Mark pending_payments as completed
    await supabase
      .from('pending_payments')
      .update({ status: 'completed' })
      .eq('payment_reference', paymentRef);

    // 6. Send receipt email if available
    const customerEmail = statusData.data.customer_email;
    if (resend && customerEmail) {
      try {
        await resend.emails.send({
          from: 'Tech4All <billing@techhubafrica.org>',
          to: customerEmail,
          subject: `Your Tech4All ${tier} Subscription is Active!`,
          html: `<p>Thank you for upgrading to <strong>Tech4All ${tier}</strong>. Your account is active with <strong>$${creditsToAward.toFixed(2)} USD</strong> image credits.</p>`,
        });
      } catch (emailErr) {
        console.warn('Receipt email error:', emailErr);
      }
    }

    return res.status(200).json({
      success: true,
      is_paid: true,
      tier: tier,
      credits: creditsToAward,
      message: `Successfully upgraded user to ${tier}!`,
    });
  } catch (e) {
    return res.status(500).json({ error: 'Sync payment exception: ' + e.message });
  }
};
