// Uploads several recordings one after another, and imports Google Drive
// links, showing the progress of each. Without this script the forms still
// post normally.
'use strict';

const menu = document.querySelector('.menu-toggle');
const sidebar = document.querySelector('#admin-sidebar');
if (menu && sidebar) {
  const setMenuOpen = (open) => {
    sidebar.toggleAttribute('data-collapsed', !open);
    menu.setAttribute('aria-expanded', String(open));
  };
  setMenuOpen(false);
  menu.hidden = false;
  menu.addEventListener('click', () => setMenuOpen(menu.getAttribute('aria-expanded') !== 'true'));
  sidebar.addEventListener('keydown', (event) => {
    if (event.key === 'Escape' && menu.getAttribute('aria-expanded') === 'true' && menu.getClientRects().length) {
      setMenuOpen(false);
      menu.focus();
    }
  });
}

const contentItems = document.querySelector('[data-content-items]');
const entryFilter = contentItems?.querySelector('[data-entry-filter]');
if (entryFilter) {
  const normalizeTitle = (value) => value.toLowerCase()
    .replace(/[\u0610-\u061a\u0640\u064b-\u065f\u0670]/g, '')
    .replace(/[أإآٱ]/g, 'ا').trim();
  const entries = [...contentItems.querySelectorAll('.entry')]
    .map((link) => ({ link, title: normalizeTitle(link.textContent) }));
  const empty = contentItems.querySelector('[data-entry-empty]');
  entryFilter.closest('label').hidden = false;
  entryFilter.addEventListener('input', () => {
    const query = normalizeTitle(entryFilter.value);
    let found = false;
    for (const { link, title } of entries) {
      link.hidden = !title.includes(query);
      found ||= !link.hidden;
    }
    empty.hidden = found;
  });
}

for (const form of document.querySelectorAll('[data-dua-drive]')) {
  form.addEventListener('submit', () => {
    form.querySelector('[data-dua-drive-button]').disabled = true;
    const status = form.querySelector('[data-dua-drive-status]');
    status.hidden = false;
    status.textContent = 'جارٍ تنزيل التسجيل وحفظه في المسودة…';
  });
}

for (const editor of document.querySelectorAll('[data-repeat-editor]')) {
  const rows = editor.querySelector('[data-repeat-rows]');
  const add = editor.querySelector('[data-repeat-add]');
  const template = editor.querySelector('template');
  const update = () => {
    add.disabled = rows.children.length >= 25;
    for (const button of rows.querySelectorAll('[data-repeat-remove]')) button.hidden = false;
  };
  add.hidden = false;
  add.addEventListener('click', () => {
    if (rows.children.length >= 25) return;
    rows.append(template.content.cloneNode(true));
    rows.lastElementChild.querySelector('input').focus();
    update();
  });
  rows.addEventListener('click', (event) => {
    const remove = event.target.closest('[data-repeat-remove]');
    if (!remove) return;
    remove.closest('.repeat-step').remove();
    add.focus();
    update();
  });
  update();
}

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
      // Not form.action: the form has a field named "action", which the
      // browser returns in place of the form's address.
      request.open('POST', form.getAttribute('action') || window.location.href);
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
        resolve({ ok: request.status < 400 && body.ok === true, message: body.message || '', revision: body.revision });
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

  // Each successful item advances the exact draft revision, not a fresh
  // revision fetched from elsewhere. Stop on failure or a concurrent edit.
  for (const form of document.querySelectorAll('[data-season-batch]')) {
    form.addEventListener('submit', async (event) => {
      event.preventDefault();
      const drive = form.dataset.seasonBatch === 'drive';
      const items = drive
        ? form.querySelector('textarea').value.split(/\r?\n/).map((line) => line.trim()).filter(Boolean).map((line) => {
            const [link, ...name] = line.split(/\s+/);
            return { link, name: name.join(' ') };
          })
        : [...form.querySelector('input[type=file]').files];
      const box = form.querySelector('[data-batch-progress]');
      box.hidden = false;
      box.replaceChildren();
      if (!items.length || items.length > 50) {
        box.textContent = 'اختر من ملف واحد إلى ٥٠ ملفًا في كل دفعة.';
        return;
      }
      const fields = Object.fromEntries(new FormData(form));
      delete fields.recording;
      delete fields.links;
      const update = overall(box, items.length);
      const rows = items.map((item) => row(box, drive ? item.name || item.link : item.name));
      const pageForms = [...document.querySelectorAll('[data-season-batch]')];
      for (const other of pageForms) lock(other, true);
      let done = 0;
      let failed = 0;
      update(0, 0);
      for (const [index, item] of items.entries()) {
        const job = [...crypto.getRandomValues(new Uint8Array(16))]
          .map((byte) => byte.toString(16).padStart(2, '0')).join('');
        let polling = drive;
        const watch = async () => {
          while (polling) {
            await new Promise((wait) => setTimeout(wait, 1000));
            if (!polling) break;
            try {
              const response = await fetch('./?job=' + job, { headers: { Accept: 'application/json' } });
              const state = await response.json();
              if (state.state === 'downloading') {
                rows[index].progress(state.received, state.total, sizeLabel(state.received) + (state.total ? ' / ' + sizeLabel(state.total) : ''));
              } else if (state.state === 'checking') {
                rows[index].progress(1, 1, 'جارٍ التحقق من الملف');
              }
            } catch (_) { /* retry next poll */ }
          }
        };
        const watching = watch();
        const result = await send(form, drive ? { ...fields, ...item, job } : fields, drive ? null : item,
          (sent, total) => rows[index].progress(sent, total, total ? Math.round(sent / total * 100) + '٪' : 'جارٍ الرفع'));
        polling = false;
        await watching;
        const ok = result.ok && Number.isSafeInteger(result.revision) && result.revision === Number(fields.revision) + 1;
        rows[index].finish(ok, ok ? 'تم الحفظ في المسودة ✓' : result.message || 'تعذّر تأكيد الحفظ');
        if (!ok) {
          failed++;
          for (const pending of rows.slice(index + 1)) pending.finish(false, 'لم يُرسل — حدّث الصفحة ثم أعد المحاولة');
          update(done, failed);
          break;
        }
        fields.revision = String(result.revision);
        done++;
        update(done, failed);
      }
      // Require reload so no stale revision or outdated episode list is reused.
      const reload = document.createElement('a');
      reload.className = 'button';
      reload.href = window.location.href;
      reload.textContent = 'تحديث قائمة الحلقات';
      box.append(reload);
    });
  }

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

for (const fields of document.querySelectorAll('.content-news-fields')) {
  const title = fields.querySelector('[name="news_title"]');
  const body = fields.querySelector('[name="news_body"]');
  const target = fields.querySelector('[name="news_route"]');
  const update = () => {
    fields.querySelector('[data-news-preview-title]').textContent = title.value || 'عنوان الإشعار';
    fields.querySelector('[data-news-preview-body]').textContent = body.value || 'نص الإشعار';
    fields.querySelector('[data-news-preview-action]').textContent = 'افتح · ' + target.selectedOptions[0].textContent;
  };
  fields.addEventListener('input', update);
  update();
}


// Fiqh staging: unsaved-edit guard and explicit citation insertion.
// No network requests, automatic citations, or publication calls.
(() => {
  const form = document.querySelector('[data-fiqh-editor]');
  if (!form) return;
  let dirty = false;
  const status = form.querySelector('[data-fiqh-dirty]');
  const markDirty = () => { dirty = true; status.hidden = false; };
  form.addEventListener('input', markDirty);
  form.addEventListener('change', markDirty);
  form.addEventListener('submit', () => { dirty = false; });
  window.addEventListener('beforeunload', (event) => {
    if (!dirty) return;
    event.preventDefault();
    event.returnValue = '';
  });
  const picker = form.querySelector('[data-fiqh-source-picker]');
  if (!picker) return;
  picker.hidden = false;
  const search = picker.querySelector('[data-fiqh-source-search]');
  const source = picker.querySelector('[data-fiqh-source]');
  const message = picker.querySelector('[data-fiqh-source-status]');
  const normalize = (value) => value.toLowerCase()
    .replace(/[\u0610-\u061a\u0640\u064b-\u065f\u0670]/g, '')
    .replace(/[أإآٱ]/g, 'ا').trim();
  search.addEventListener('input', () => {
    const query = normalize(search.value);
    for (const option of source.options) {
      option.hidden = !!option.value && !normalize(option.textContent).includes(query);
    }
    if (source.selectedOptions[0]?.hidden) source.value = '';
  });
  picker.querySelector('[data-fiqh-add-source]').addEventListener('click', () => {
    const school = picker.querySelector('[data-fiqh-school]').value;
    const ar = picker.querySelector('[data-fiqh-locator-ar]').value.trim();
    const en = picker.querySelector('[data-fiqh-locator-en]').value.trim();
    if (!source.value || !ar || !en) {
      message.textContent = 'اختر المصدر واكتب موضع الاستشهاد باللغتين.';
      return;
    }
    const target = form.elements.namedItem(school + '_details');
    try {
      let details = JSON.parse(target.value || '{}');
      if (Array.isArray(details) && details.length === 0) details = {};
      if (!details || typeof details !== 'object' || Array.isArray(details)) throw new Error('shape');
      const refs = details.sourceReferences ?? [];
      if (!Array.isArray(refs)) throw new Error('shape');
      if (refs.some((ref) => ref?.sourceId === source.value && ref?.locator?.ar === ar && ref?.locator?.en === en)) {
        message.textContent = 'هذا الاستشهاد موجود بالفعل.';
        return;
      }
      details.sourceReferences = [...refs, { sourceId: source.value, locator: { ar, en } }];
      target.value = JSON.stringify(details, null, 2);
      markDirty();
      message.textContent = 'أُضيف المرجع إلى النموذج فقط. احفظ المسودة لتسجيل التغيير.';
    } catch {
      message.textContent = 'راجع JSON الخاص بالمذهب أولًا. لم تتغير البيانات.';
    }
  });
})();


// Draft-only, opt-in autosave. Never retry an ambiguous write or advance a
// publication form's revision; a reload is required before publishing.
(() => {
  const form = document.querySelector('[data-fiqh-editor]');
  const toggle = form?.querySelector('[data-fiqh-autosave]');
  if (!toggle) return;
  const status = form.querySelector('[data-fiqh-autosave-status]');
  const revision = form.elements.namedItem('fiqh_revision');
  const buttons = [...form.querySelectorAll('button[type="submit"], button:not([type])')];
  const reviews = [...document.querySelectorAll('#fiqh-review form')];
  let timer, saving = false, stopped = false, changed = false;
  const snapshot = () => JSON.stringify([...new FormData(form)].filter(([key]) => key !== 'fiqh_revision'));
  let saved = snapshot();
  toggle.closest('[data-fiqh-autosave-option]').hidden = false;
  const blockReview = () => {
    for (const review of reviews) for (const button of review.querySelectorAll('button')) button.disabled = true;
  };
  const schedule = () => {
    clearTimeout(timer);
    if (!toggle.checked || stopped || saving || snapshot() === saved) return;
    timer = setTimeout(save, 1800);
  };
  const stop = (message) => {
    stopped = true;
    toggle.checked = false;
    toggle.disabled = true;
    blockReview();
    status.textContent = message;
  };
  async function save() {
    if (!toggle.checked || stopped || saving || !form.checkValidity() || snapshot() === saved) return;
    const before = snapshot();
    const lease = Number(revision.value);
    const body = new FormData(form);
    body.set('action', 'fiqh_autosave');
    body.set('autosave_enabled', 'yes');
    saving = true;
    buttons.forEach(button => { button.disabled = true; });
    blockReview();
    status.textContent = 'جارٍ حفظ المسودة…';
    try {
      const response = await fetch(form.action, {method:'POST', body, credentials:'same-origin', headers:{Accept:'application/json'}});
      const result = await response.json();
      if (!response.ok || result.ok !== true || result.id !== form.elements.namedItem('id').value
          || !Number.isSafeInteger(result.revision) || ![lease,lease+1].includes(result.revision)) {
        throw new Error('unconfirmed write');
      }
      revision.value = String(result.revision);
      saved = before;
      changed = changed || result.changed === true;
      status.textContent = 'حُفظت المسودة v' + result.revision + '؛ أعد فتح الصفحة قبل النشر.';
      // Existing unsaved guard stays conservative; clearing it without
      // refreshing the server-rendered review/preview could mislead editors.
    } catch {
      stop('توقف الحفظ التلقائي: تعارض أو تعذّر تأكيد الحفظ. احتفظ بنسخة من مدخلاتك وافتح أحدث إصدار للمقارنة.');
    } finally {
      saving = false;
      buttons.forEach(button => { button.disabled = stopped; });
      if (changed || stopped) blockReview();
      schedule();
    }
  }
  toggle.addEventListener('change', schedule);
  form.addEventListener('input', schedule);
  form.addEventListener('change', schedule);
  form.addEventListener('submit', event => {
    clearTimeout(timer);
    if (saving || stopped) { event.preventDefault(); return; }
    toggle.checked = false;
  });
  // Source and evidence builders update named JSON fields programmatically.
  form.addEventListener('click', event => {
    if (event.target.closest('[data-fiqh-add-source], [data-evidence-add]')) schedule();
  });
})();

// Guided evidence entry; server-side canonical validation remains authoritative.
(() => {
  const form = document.querySelector('[data-fiqh-editor]');
  const builder = form?.querySelector('[data-fiqh-evidence-builder]');
  if (!builder) return;
  const get = key => builder.querySelector('[data-evidence-' + key + ']');
  const text = key => ({
    ar: builder.querySelector('[data-evidence-field="' + key + '_ar"]').value.trim(),
    en: builder.querySelector('[data-evidence-field="' + key + '_en"]').value.trim()
  });
  const type = get('type');
  const sync = () => {
    get('quran').hidden = type.value !== 'quran';
    get('hadith').hidden = type.value !== 'hadith';
  };
  builder.hidden = false;
  type.addEventListener('change', sync);
  sync();
  get('add').addEventListener('click', () => {
    const id = get('id').value.trim(), source = get('source').value;
    const status = get('status');
    if (!/^[a-z0-9][a-z0-9_-]{0,95}$/.test(id) || !source) {
      status.textContent = 'أدخل معرّفًا صحيحًا واختر مصدرًا.'; return;
    }
    try {
      const target = form.elements.namedItem('evidence');
      const list = JSON.parse(target.value || '[]');
      if (!Array.isArray(list) || list.some(item => item?.id === id)) throw new Error('duplicate or shape');
      const entry = {id, type:type.value, text:text('text'), reference:text('reference'), explanation:text('explanation'), sourceIds:[source]};
      if (type.value === 'quran') {
        const [surah,firstAyah,lastAyah] = ['surah','first','last'].map(key => Number(get(key).value));
        if (![surah,firstAyah,lastAyah].every(Number.isSafeInteger) || surah<1 || surah>114 || firstAyah<1 || lastAyah<firstAyah) throw new Error('range');
        entry.quranLocator = {surah,firstAyah,lastAyah};
      }
      if (type.value === 'hadith') {
        entry.grading = text('grading');
        entry.gradingAttribution = text('gradingAttribution');
        entry.hadithLocator = {collectionSourceId:source, number:text('number'), book:text('book'), chapter:text('chapter'), editionLocator:text('editionLocator')};
      }
      target.value = JSON.stringify([...list,entry],null,2);
      target.dispatchEvent(new Event('input',{bubbles:true}));
      status.textContent = 'أُضيف إلى النموذج. راجع النص والمصدر قبل الحفظ.';
    } catch {
      status.textContent = 'راجع معرّف الدليل أو حدود الآيات أو JSON. لم يُضف شيء.';
    }
  });
})();
