// Uploads several recordings one after another, and imports Google Drive
// links, showing the progress of each. Without this script the forms still
// post normally.
'use strict';

(() => {
  const sizeLabel = (bytes) => {
    if (!bytes) return '';
    const mb = bytes / 1048576;
    return mb >= 1 ? `${mb.toFixed(1)} م.ب` : `${Math.max(1, Math.round(bytes / 1024))} ك.ب`;
  };

  /** One row: name, a progress bar and a status line. */
  const row = (box, name) => {
    const item = document.createElement('div');
    item.className = 'upload';
    const title = document.createElement('bdi');
    title.textContent = name;
    const bar = document.createElement('progress');
    bar.max = 1;
    bar.value = 0;
    const status = document.createElement('span');
    status.className = 'upload-status';
    status.textContent = 'في الانتظار';
    item.append(title, bar, status);
    box.append(item);
    return {
      progress(done, total, text) {
        if (total > 0) bar.value = done / total;
        else bar.removeAttribute('value');
        status.textContent = text;
      },
      finish(ok, text) {
        bar.value = ok ? 1 : bar.value;
        item.classList.add(ok ? 'ok' : 'failed');
        status.textContent = text;
      },
    };
  };

  const overall = (box, count) => {
    const item = document.createElement('div');
    item.className = 'upload overall';
    const label = document.createElement('strong');
    const bar = document.createElement('progress');
    bar.max = count;
    bar.value = 0;
    item.append(label, bar);
    box.prepend(item);
    return (done, failed) => {
      bar.value = done;
      label.textContent = `اكتمل ${done} من ${count}` + (failed ? ` · تعذّر ${failed}` : '');
    };
  };

  const send = (form, fields, file, onProgress) =>
    new Promise((resolve) => {
      const data = new FormData();
      for (const [key, value] of Object.entries(fields)) data.append(key, value);
      if (file) data.append('recording', file);
      const request = new XMLHttpRequest();
      request.open('POST', form.action || window.location.href);
      request.setRequestHeader('Accept', 'application/json');
      if (file) {
        request.upload.onprogress = (event) =>
          onProgress(event.loaded, event.lengthComputable ? event.total : 0);
      }
      request.onload = () => {
        let body = {};
        try {
          body = JSON.parse(request.responseText);
        } catch (_) {
          body = { ok: false, message: 'استجابة غير متوقعة من الموقع.' };
        }
        resolve({ ok: request.status < 400 && body.ok === true, message: body.message || '' });
      };
      request.onerror = () => resolve({ ok: false, message: 'انقطع الاتصال أثناء الرفع.' });
      request.send(data);
    });

  const hidden = (form) => ({
    csrf: form.querySelector('[name=csrf]').value,
    action: form.querySelector('[name=action]').value,
  });

  const lock = (form, locked) => {
    for (const control of form.querySelectorAll('input, textarea, button')) control.disabled = locked;
  };

  const uploadForm = document.getElementById('upload-form');
  const uploadBox = document.getElementById('upload-progress');
  if (uploadForm && uploadBox) {
    uploadForm.addEventListener('submit', async (event) => {
      const input = uploadForm.querySelector('input[type=file]');
      if (!input.files.length) return;
      event.preventDefault();
      const files = [...input.files];
      const fields = hidden(uploadForm);
      uploadBox.hidden = false;
      uploadBox.replaceChildren();
      const update = overall(uploadBox, files.length);
      const rows = files.map((file) => row(uploadBox, `${file.name} · ${sizeLabel(file.size)}`));
      lock(uploadForm, true);
      let done = 0;
      let failed = 0;
      update(0, 0);
      for (const [index, file] of files.entries()) {
        const result = await send(uploadForm, fields, file, (sent, total) =>
          rows[index].progress(sent, total, total ? `${Math.round((sent / total) * 100)}٪` : 'جارٍ الرفع'),
        );
        rows[index].finish(result.ok, result.ok ? 'تم ✓' : result.message);
        if (result.ok) done++;
        else failed++;
        update(done, failed);
      }
      lock(uploadForm, false);
      if (done > 0) {
        const reload = document.createElement('a');
        reload.className = 'button';
        reload.href = window.location.href;
        reload.textContent = 'تحديث قائمة التسجيلات';
        uploadBox.append(reload);
      }
    });
  }

  const driveForm = document.getElementById('drive-form');
  const driveBox = document.getElementById('drive-progress');
  if (driveForm && driveBox) {
    driveForm.addEventListener('submit', async (event) => {
      const lines = driveForm
        .querySelector('textarea')
        .value.split(/\r?\n/)
        .map((line) => line.trim())
        .filter(Boolean);
      if (!lines.length) return;
      event.preventDefault();
      const fields = hidden(driveForm);
      driveBox.hidden = false;
      driveBox.replaceChildren();
      const update = overall(driveBox, lines.length);
      const items = lines.map((line) => {
        const [link, ...rest] = line.split(/\s+/);
        return { link, name: rest.join(' ') };
      });
      const rows = items.map((item) => row(driveBox, item.name || item.link));
      lock(driveForm, true);
      let done = 0;
      let failed = 0;
      update(0, 0);
      for (const [index, item] of items.entries()) {
        const job = [...crypto.getRandomValues(new Uint8Array(16))]
          .map((byte) => byte.toString(16).padStart(2, '0'))
          .join('');
        rows[index].progress(0, 0, 'جارٍ التنزيل على الموقع');
        let polling = true;
        const poll = async () => {
          while (polling) {
            await new Promise((wait) => setTimeout(wait, 1000));
            if (!polling) break;
            try {
              const response = await fetch(`./?job=${job}`, { headers: { Accept: 'application/json' } });
              const state = await response.json();
              if (state.state === 'downloading') {
                rows[index].progress(
                  state.received,
                  state.total,
                  state.total
                    ? `${sizeLabel(state.received)} من ${sizeLabel(state.total)}`
                    : sizeLabel(state.received) || 'جارٍ التنزيل',
                );
              } else if (state.state === 'checking') {
                rows[index].progress(1, 1, 'جارٍ التحقق من الملف');
              }
            } catch (_) {
              // The next poll tries again.
            }
          }
        };
        const watching = poll();
        const result = await send(driveForm, { ...fields, link: item.link, name: item.name, job }, null, () => {});
        polling = false;
        await watching;
        rows[index].finish(result.ok, result.ok ? result.message || 'تم ✓' : result.message);
        if (result.ok) done++;
        else failed++;
        update(done, failed);
      }
      lock(driveForm, false);
      if (done > 0) {
        const reload = document.createElement('a');
        reload.className = 'button';
        reload.href = window.location.href;
        reload.textContent = 'تحديث قائمة التسجيلات';
        driveBox.append(reload);
      }
    });
  }
})();

// Searching long lists: a box with data-filter-select="id" narrows that
// select's options; data-complete-only="id" keeps complete reciters only;
// data-filter-list="selector" hides list items that do not match.
(() => {
  const fold = (text) =>
    text
      .toLowerCase()
      .normalize('NFKD')
      .replace(/[ً-ْٰـ]/g, '')
      .replace(/[أإآٱ]/g, 'ا')
      .replace(/ة/g, 'ه')
      .replace(/ى/g, 'ي');

  const refresh = (select) => {
    const query = fold(document.querySelector(`[data-filter-select="${select.id}"]`)?.value || '');
    const completeOnly = document.querySelector(`[data-complete-only="${select.id}"]`)?.checked;
    for (const option of select.options) {
      option.hidden =
        (query && !fold(option.textContent).includes(query)) ||
        (completeOnly && option.dataset.complete !== '1');
    }
  };
  for (const input of document.querySelectorAll('[data-filter-select], [data-complete-only]')) {
    const select = document.getElementById(input.dataset.filterSelect || input.dataset.completeOnly);
    if (select) input.addEventListener('input', () => refresh(select));
  }
  for (const input of document.querySelectorAll('[data-filter-list]')) {
    input.addEventListener('input', () => {
      const query = fold(input.value);
      for (const item of document.querySelectorAll(input.dataset.filterList)) {
        item.hidden = query !== '' && !fold(item.textContent).includes(query);
      }
    });
  }
})();
