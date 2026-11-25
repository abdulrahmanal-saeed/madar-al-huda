'use strict';
const form = document.getElementById('privacy-request');
const button = form.querySelector('button');
const status = document.getElementById('request-status');
button.disabled = false;
form.addEventListener('submit', async (event) => {
  event.preventDefault();
  if (button.disabled) return;
  button.disabled = true;
  status.textContent = 'جارٍ الإرسال… / Sending…';
  try {
    const kind = document.getElementById('request-kind').value;
    const contact = document.getElementById('request-email').value.trim();
    const detail = document.getElementById('request-message').value.trim();
    const response = await fetch('./?report=1', {
      method: 'POST',
      credentials: 'omit',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({
        kind: 'problem',
        message: '[Privacy request: ' + kind + ']\n' + detail,
        contact,
        app: 'Privacy website'
      })
    });
    const receipt = await response.json();
    if (!response.ok || receipt.ok !== true) throw new Error('request failed');
    form.reset();
    status.textContent = 'تم استلام طلبك للمراجعة. / Your request has been received for review.';
  } catch (_) {
    status.textContent = 'تعذّر إرسال الطلب. حاول مرة أخرى لاحقًا. / Could not send the request. Please try again later.';
  } finally {
    button.disabled = false;
  }
});
