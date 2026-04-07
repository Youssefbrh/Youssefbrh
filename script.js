/* ════════════════════════════════════════════════════════════════
   ROMANCE LETTER · script.js
   ════════════════════════════════════════════════════════════════
   Table of contents
     1.  CONFIG ← ✏️  Edit this section to customize everything
     2.  DOM References
     3.  Content Injection
     4.  Screen Transition System
     5.  Petal Particle Generator
     6.  Birthday Validation
     7.  Letter Reveal (staggered paragraph fade-in)
     8.  Easter Egg: Lily Corner Blooms
     9.  Event Listeners
    10.  Init

   AUDIO: Search "AUDIO BLOCK" to find the optional music toggle.
════════════════════════════════════════════════════════════════ */


/* ════════════════════════════════════════════════════════════════
   1.  CONFIG
   ════════════════════════════════════════════════════════════════
   This is the ONLY section you need to edit.
   All text, birthday, and copy lives here.
════════════════════════════════════════════════════════════════ */

const CONFIG = {

  // ── Landing screen ───────────────────────────────────────────
  landingTitle:    "For Sugar",
  landingSubtitle: "There are things I've been meaning to say…",


  // ── Birthday Gate ─────────────────────────────────────────────
  //
  // ⚠️  CHANGE THESE VALUES before sharing the QR code.
  //
  // ⚠️  SECURITY NOTE: This is a sentimental access gate, NOT
  //     real security. The birthday values below are visible in
  //     plain text to anyone who views the page source. The
  //     purpose is to create a personal, intimate moment for
  //     the recipient — not to restrict access to anyone.
  //
  birthday: {
    day:   15,   // ← EDIT: day of birth (1–31)
    month: 3,    // ← EDIT: month of birth (1–12). March = 3, October = 10, etc.
    year:  2000, // ← EDIT: 4-digit birth year
  },

  birthdayPrompt:   "Just one little thing before you read this…",
  birthdayQuestion: "When's your birthday, love?",
  birthdayError:    "Hmm, that doesn't seem right. Try again?",


  // ── Letter ────────────────────────────────────────────────────
  letterTitle: "A Letter For You",

  // The "Dear ___," line at the top of the letter
  salutation: "Dear Sugar,",

  // ──────────────────────────────────────────────────────────────
  //  YOUR LETTER TEXT
  //  ↓↓ Replace the placeholder paragraphs below with your
  //     real message before sharing the QR code. ↓↓
  //
  //  • Each string in this array is one paragraph.
  //  • Use \n inside a string for a line break within a paragraph.
  //  • Paragraphs will fade in one by one when the letter opens.
  // ──────────────────────────────────────────────────────────────
  letterParagraphs: [

    // ↓↓ PASTE YOUR LETTER HERE — replace everything between these markers ↓↓

    "I've been sitting with this for a while now — turning the right words over, setting them down, starting again. Not because I don't know what I want to say, but because I wanted to say it well. You deserve that.",

    "There are things I did wrong. I know which ones. And I know that acknowledging them doesn't undo them — but I want you to know that I see them clearly, without excuses layered on top.",

    "You are someone who shows up with your whole heart. I haven't always matched that. That's something I carry, and something I want to be better at — not as a promise made in a hard moment, but as a quiet, steady intention.",

    "I miss you the way you miss something that made ordinary days feel lighter. I miss the specific version of myself that existed when you were close.",

    "I'm not asking you to forget, or to rush. I just wanted you to know — in writing, in something you can hold — that you matter to me. That I'm sorry. And that I mean it.",

    // ↑↑ END OF PLACEHOLDER TEXT — replace everything above this line ↑↑

  ],

  // ── Closing ───────────────────────────────────────────────────
  closingSignature: "— Yours",
  closingNote:      "Thank you for reading.",

};


/* ════════════════════════════════════════════════════════════════
   2.  DOM REFERENCES
════════════════════════════════════════════════════════════════ */

const DOM = {
  // Screens
  screens: {
    landing:  document.getElementById('screen-landing'),
    birthday: document.getElementById('screen-birthday'),
    letter:   document.getElementById('screen-letter'),
    closing:  document.getElementById('screen-closing'),
  },

  // Landing
  landingTitle:     document.getElementById('landing-title'),
  landingSubtitle:  document.getElementById('landing-subtitle'),
  btnOpen:          document.getElementById('btn-open'),

  // Birthday
  birthdayPrompt:   document.getElementById('birthday-prompt'),
  birthdayQuestion: document.getElementById('birthday-question'),
  birthdayForm:     document.getElementById('birthday-form'),
  birthdayError:    document.getElementById('birthday-error'),
  bdDay:            document.getElementById('bd-day'),
  bdMonth:          document.getElementById('bd-month'),
  bdYear:           document.getElementById('bd-year'),

  // Letter
  letterTitle:      document.getElementById('letter-title'),
  letterSalutation: document.getElementById('letter-salutation'),
  letterBody:       document.getElementById('letter-body'),
  letterSignature:  document.getElementById('letter-signature'),
  letterContinue:   document.getElementById('letter-continue'),
  btnToClosing:     document.getElementById('btn-to-closing'),

  // Closing
  closingNote:  document.getElementById('closing-note'),
  btnReplay:    document.getElementById('btn-replay'),

  // Easter egg corners
  lilyCorners: document.querySelectorAll('.lily-corner'),

  // Petal containers
  petalsLanding:  document.getElementById('petals-landing'),
  petalsBirthday: document.getElementById('petals-birthday'),
  petalsLetter:   document.getElementById('petals-letter'),
};


/* ════════════════════════════════════════════════════════════════
   3.  CONTENT INJECTION
   Populates DOM from CONFIG so you only ever edit CONFIG.
════════════════════════════════════════════════════════════════ */

function injectContent() {
  // Landing
  DOM.landingTitle.textContent    = CONFIG.landingTitle;
  DOM.landingSubtitle.textContent = CONFIG.landingSubtitle;

  // Birthday gate
  DOM.birthdayPrompt.textContent   = CONFIG.birthdayPrompt;
  DOM.birthdayQuestion.textContent = CONFIG.birthdayQuestion;

  // Letter header & footer
  DOM.letterTitle.textContent      = CONFIG.letterTitle;
  DOM.letterSalutation.textContent = CONFIG.salutation;
  DOM.letterSignature.textContent  = CONFIG.closingSignature;

  // Letter paragraphs — built from CONFIG.letterParagraphs array
  const fragment = document.createDocumentFragment();
  CONFIG.letterParagraphs.forEach((text) => {
    const p = document.createElement('p');
    p.className = 'letter-paragraph';
    // Support intentional \n line breaks within a paragraph
    p.innerHTML = text.replace(/\n/g, '<br>');
    fragment.appendChild(p);
  });
  DOM.letterBody.appendChild(fragment);

  // Closing
  DOM.closingNote.textContent = CONFIG.closingNote;

  // Update page title from CONFIG
  document.title = CONFIG.landingTitle;
}


/* ════════════════════════════════════════════════════════════════
   4.  SCREEN TRANSITION SYSTEM
════════════════════════════════════════════════════════════════ */

let currentScreen = DOM.screens.landing;

/**
 * Fade between screens. Optionally run a callback after the new
 * screen becomes visible.
 */
function transitionTo(targetScreen, afterCallback) {
  if (targetScreen === currentScreen) return;

  const leaving = currentScreen;
  currentScreen = targetScreen;

  // Fade out the leaving screen
  leaving.classList.add('exiting');
  leaving.classList.remove('active');

  // Bring in the new screen after the CSS exit transition
  setTimeout(() => {
    leaving.classList.remove('exiting');
    targetScreen.classList.add('active');

    // Reset scroll position on the new screen
    targetScreen.scrollTop = 0;

    if (typeof afterCallback === 'function') afterCallback();
  }, 660);
}


/* ════════════════════════════════════════════════════════════════
   5.  PETAL PARTICLE GENERATOR
   Creates floating petal elements with randomized CSS properties.
════════════════════════════════════════════════════════════════ */

/**
 * @param {HTMLElement} container  The .petals div to fill
 * @param {number}      count      Number of petals to spawn
 */
function createPetals(container, count = 18) {
  const fragment = document.createDocumentFragment();

  for (let i = 0; i < count; i++) {
    const petal = document.createElement('div');
    petal.className = 'petal';

    const size    = 6  + Math.random() * 11;            // px width
    const left    = Math.random() * 106 - 3;            // % (allow slight bleed)
    const dur     = 13 + Math.random() * 14;            // seconds per cycle
    const delay   = -(Math.random() * dur);             // start mid-cycle so screen never looks empty
    const drift   = (Math.random() - 0.5) * 180;       // horizontal drift in px
    const spin    = (Math.random() - 0.5) * 500;       // total rotation degrees
    const opacity = 0.22 + Math.random() * 0.28;

    petal.style.cssText = `
      width: ${size}px;
      height: ${(size * 1.8).toFixed(1)}px;
      left: ${left.toFixed(1)}%;
      --drift: ${drift.toFixed(0)}px;
      --spin: ${spin.toFixed(0)}deg;
      --petal-opacity: ${opacity.toFixed(2)};
      animation-duration: ${dur.toFixed(1)}s;
      animation-delay: ${delay.toFixed(1)}s;
    `;

    fragment.appendChild(petal);
  }

  container.appendChild(fragment);
}


/* ════════════════════════════════════════════════════════════════
   6.  BIRTHDAY VALIDATION
════════════════════════════════════════════════════════════════ */

function validateBirthday(day, month, year) {
  return (
    parseInt(day,   10) === CONFIG.birthday.day   &&
    parseInt(month, 10) === CONFIG.birthday.month &&
    parseInt(year,  10) === CONFIG.birthday.year
  );
}

function handleBirthdaySubmit(e) {
  e.preventDefault();

  const day   = DOM.bdDay.value.trim();
  const month = DOM.bdMonth.value.trim();
  const year  = DOM.bdYear.value.trim();

  // Clear previous error text
  DOM.birthdayError.textContent = '';

  // Basic empty-check
  if (!day || !month || !year) {
    DOM.birthdayError.textContent = 'Please fill in all three fields.';
    return;
  }

  if (validateBirthday(day, month, year)) {
    // Correct — unlock the letter
    transitionTo(DOM.screens.letter, () => {
      revealLetter();
      bloomLilies();
    });
  } else {
    // Wrong — gentle error + shake
    DOM.birthdayError.textContent = CONFIG.birthdayError;
    DOM.birthdayForm.classList.add('shake');
    setTimeout(() => DOM.birthdayForm.classList.remove('shake'), 500);

    // Clear inputs so they can try again cleanly
    DOM.bdDay.value   = '';
    DOM.bdMonth.value = '';
    DOM.bdYear.value  = '';
    DOM.bdDay.focus();
  }
}


/* ════════════════════════════════════════════════════════════════
   7.  LETTER REVEAL
   Staggered fade-in for each paragraph. The "continue" button
   appears after the last paragraph finishes fading in.
════════════════════════════════════════════════════════════════ */

let letterRevealed = false;

function revealLetter() {
  if (letterRevealed) return;
  letterRevealed = true;

  const paragraphs = DOM.letterBody.querySelectorAll('.letter-paragraph');
  const BASE_DELAY    = 420;   // ms before first paragraph
  const STAGGER       = 230;   // ms between each paragraph
  const LAST_P_INDEX  = paragraphs.length - 1;

  paragraphs.forEach((p, i) => {
    setTimeout(() => p.classList.add('revealed'), BASE_DELAY + i * STAGGER);
  });

  // Show the "continue" button after the last paragraph is revealed
  const continueDelay = BASE_DELAY + LAST_P_INDEX * STAGGER + 1000;
  setTimeout(() => {
    DOM.letterContinue.classList.add('visible');
    DOM.letterContinue.removeAttribute('aria-hidden');
  }, continueDelay);
}

function resetLetter() {
  letterRevealed = false;
  DOM.letterBody.querySelectorAll('.letter-paragraph').forEach(p => {
    p.classList.remove('revealed');
  });
  DOM.letterContinue.classList.remove('visible');
  DOM.letterContinue.setAttribute('aria-hidden', 'true');
}


/* ════════════════════════════════════════════════════════════════
   8.  EASTER EGG: LILY CORNER BLOOMS
   Four stylized lily SVGs animate in at the screen corners
   when the letter is first unlocked.
════════════════════════════════════════════════════════════════ */

// Minimalist lily SVG — petals arranged toward top-left corner
const LILY_SVG = `<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg" aria-hidden="true" focusable="false">
  <ellipse cx="26" cy="36" rx="9" ry="25"
    transform="rotate(-35 26 36)"
    fill="rgba(232,180,184,0.55)" />
  <ellipse cx="48" cy="20" rx="9" ry="25"
    fill="rgba(220,160,170,0.48)" />
  <ellipse cx="20" cy="52" rx="9" ry="25"
    transform="rotate(-88 20 52)"
    fill="rgba(212,168,106,0.32)" />
  <ellipse cx="40" cy="30" rx="9" ry="22"
    transform="rotate(-58 40 30)"
    fill="rgba(232,180,184,0.38)" />
  <circle cx="34" cy="40" r="7"
    fill="rgba(212,168,106,0.65)" />
  <circle cx="34" cy="40" r="3.5"
    fill="rgba(212,168,106,0.95)" />
  <line x1="34" y1="40" x2="34" y2="16"
    stroke="rgba(212,168,106,0.45)" stroke-width="1.4" stroke-linecap="round"/>
  <line x1="34" y1="40" x2="14" y2="34"
    stroke="rgba(212,168,106,0.4)"  stroke-width="1.4" stroke-linecap="round"/>
  <circle cx="34" cy="16" r="2.5" fill="rgba(232,180,184,0.7)" />
  <circle cx="14" cy="34" r="2.5" fill="rgba(232,180,184,0.7)" />
</svg>`;

function bloomLilies() {
  DOM.lilyCorners.forEach((corner) => {
    corner.innerHTML = LILY_SVG;
  });

  // Stagger each corner's bloom
  DOM.lilyCorners.forEach((corner, i) => {
    setTimeout(() => corner.classList.add('bloomed'), 250 + i * 160);
  });
}

function unbloomLilies() {
  DOM.lilyCorners.forEach((corner) => {
    corner.classList.remove('bloomed');
    // Clear innerHTML after transition ends
    setTimeout(() => { corner.innerHTML = ''; }, 1200);
  });
}


/* ════════════════════════════════════════════════════════════════
   AUDIO BLOCK (optional — disabled by default)
   ════════════════════════════════════════════════════════════════
   To enable background music:
     1. Add your MP3 file at:  assets/music.mp3
     2. Uncomment the <audio> and <button> in index.html
     3. Remove the /* and * / comment markers around this block

/*
const audioEl     = document.getElementById('bg-music');
const btnAudio    = document.getElementById('btn-audio');
let   audioActive = false;

function toggleAudio() {
  if (!audioEl || !btnAudio) return;

  if (audioActive) {
    audioEl.pause();
    btnAudio.textContent = '♪';
    btnAudio.setAttribute('aria-pressed', 'false');
    audioActive = false;
  } else {
    audioEl.play()
      .then(() => {
        btnAudio.textContent = '■';
        btnAudio.setAttribute('aria-pressed', 'true');
        audioActive = true;
      })
      .catch(() => {
        // Browser blocked autoplay — user must tap again
      });
  }
}

if (btnAudio) btnAudio.addEventListener('click', toggleAudio);
*/


/* ════════════════════════════════════════════════════════════════
   9.  EVENT LISTENERS
════════════════════════════════════════════════════════════════ */

function attachListeners() {

  // Landing → Birthday gate
  DOM.btnOpen.addEventListener('click', () => {
    transitionTo(DOM.screens.birthday);
  });

  // Birthday form submit
  DOM.birthdayForm.addEventListener('submit', handleBirthdaySubmit);

  // Auto-advance focus: day (2 digits) → month
  DOM.bdDay.addEventListener('input', () => {
    if (DOM.bdDay.value.length >= 2) DOM.bdMonth.focus();
  });

  // Auto-advance focus: month (2 digits) → year
  DOM.bdMonth.addEventListener('input', () => {
    if (DOM.bdMonth.value.length >= 2) DOM.bdYear.focus();
  });

  // Allow pressing Enter in year field to submit
  DOM.bdYear.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') DOM.birthdayForm.requestSubmit();
  });

  // Letter "continue" button → closing screen
  if (DOM.btnToClosing) {
    DOM.btnToClosing.addEventListener('click', () => {
      transitionTo(DOM.screens.closing);
    });
  }

  // Closing → replay from landing
  DOM.btnReplay.addEventListener('click', () => {
    // Fade out lilies
    unbloomLilies();

    // Reset letter so it can be re-revealed
    resetLetter();

    // Clear birthday form for privacy / re-entry
    DOM.bdDay.value   = '';
    DOM.bdMonth.value = '';
    DOM.bdYear.value  = '';
    DOM.birthdayError.textContent = '';

    // Return to landing
    transitionTo(DOM.screens.landing);
  });

}


/* ════════════════════════════════════════════════════════════════
   10.  INIT
════════════════════════════════════════════════════════════════ */

function init() {
  injectContent();

  // Spawn petals in each container
  createPetals(DOM.petalsLanding,  20);
  createPetals(DOM.petalsBirthday, 14);
  createPetals(DOM.petalsLetter,   16);

  attachListeners();
}

document.addEventListener('DOMContentLoaded', init);
