// app.js - Nampo GoGo Platform Advanced Delivery-Style Single Page App

// Fail-safe global variables
let partnerDetailModal = null;
let qrScannerModal = null;
let logSnsModal = null;

let partnersList = [];
let updateHistoryList = [];

let currentLang = 'kr';
let appMode = 'tourist'; // 'tourist' or 'merchant'
let activeTab = 'tourist-explore'; // Dynamic active tab panel ID

// User Auth states
let currentUser = localStorage.getItem('nampogogo_user') || null;
let currentUserRole = localStorage.getItem('nampogogo_user_role') || 'visitor'; // 'visitor', 'merchant', 'admin'
let userStamps = [];

// Filtering & Sorting
let activeSubcatFilter = 'all';
let filterPartnerOnly = false;

// Media Upload Temporary Arrays (Holds Base64 strings)
let tempUploadedMedia = [];
let selectedThumbnailBase64 = "";

// Multi-Language Reference
let translations = {};

// Direct Global Touch Handler for Mobile Compatibility (Ensures 100% click/touch reliability)
window.handleModeSelect = function(mode) {
  console.log(`🎯 handleModeSelect triggered with mode: ${mode}`);
  const introScreen = document.getElementById('intro-screen');
  const appWorkspace = document.getElementById('app-workspace');

  if (!introScreen || !appWorkspace) {
    console.error("🚨 Missing core workspaces to switch screens!");
    return;
  }

  appMode = mode;
  introScreen.classList.add('hidden');
  appWorkspace.classList.remove('hidden');

  renderDynamicNavigationDock();

  if (mode === 'tourist') {
    switchTabPanel('tourist-explore');
  } else {
    if (currentUser && currentUserRole === 'merchant') {
      switchTabPanel('merchant-manage');
    } else {
      switchTabPanel('merchant-auth');
    }
  }
};

// Safe Initialization Hook (Robust try-catch sandbox isolation)
document.addEventListener('DOMContentLoaded', () => {
  console.log("🚀 Nampo GoGo App Initialization Starting...");
  
  // Bind core DOM Elements
  partnerDetailModal = document.getElementById('partner-detail-modal');
  qrScannerModal = document.getElementById('qr-scanner-modal');
  logSnsModal = document.getElementById('log-sns-modal');

  // Load Seed and Translations Safely
  const seed = window.NampoGoGoData || { translations: {}, partners: [], updateHistory: [] };
  translations = seed.translations || {};

  // Safe isolated module executor helper to prevent single-point failures from stopping the app
  function runSafe(moduleName, fn) {
    try {
      console.log(`[Module Init] Loading: ${moduleName}`);
      fn();
      console.log(`[Module Init] Success: ${moduleName}`);
    } catch (err) {
      console.error(`🚨 [Module Error] Module "${moduleName}" failed to execute!`, err);
    }
  }

  runSafe('LocalStorage Seed', () => initLocalStorageSeed(seed));
  runSafe('Application State Load', () => loadApplicationState());
  runSafe('User Stamps Load', () => loadUserStamps());
  runSafe('Lucide Icons', () => initLucide());
  runSafe('Language Manager', () => setupLanguage());
  runSafe('Intro Mode Switcher', () => setupIntroModeSelection());
  runSafe('Updates Notices Panel', () => setupUpdatePanel());
  runSafe('AI Planner System', () => setupAIPlanner());
  runSafe('Cross-tab Sync', () => setupCrossTabSync());
  runSafe('Tourist Auth System', () => setupAuthSystem());
  runSafe('Merchant Control System', () => setupMerchantSystem());
  runSafe('Interactive QR Checkin Scanner', () => setupInteractiveScans());

  // Render initial views
  runSafe('Render Partners Board', () => renderPartnersList());
  runSafe('Render Travel Log Timeline', () => renderTravelLog());

  // Setup modal close actions
  runSafe('Modal Buttons Bind', () => setupModalCloseButtons());
  
  console.log("🎉 Nampo GoGo App Fully Initialized!");
});

function initLocalStorageSeed(seed) {
  // Seed Users
  if (!localStorage.getItem('nampogogo_users')) {
    const defaultUsers = [
      { id: 'admin', pw: 'admin123', role: 'admin' },
      { id: 'owner_klounge', pw: 'klounge123', role: 'merchant' },
      { id: 'owner_jagalchi', pw: 'jagalchi123', role: 'merchant' }
    ];
    localStorage.setItem('nampogogo_users', JSON.stringify(defaultUsers));
  }

  // Seed Partners list
  if (!localStorage.getItem('nampogogo_partners_v3') && seed.partners) {
    localStorage.setItem('nampogogo_partners_v3', JSON.stringify(seed.partners));
  }

  // Seed Notices
  if (!localStorage.getItem('nampogogo_notices') && seed.updateHistory) {
    localStorage.setItem('nampogogo_notices', JSON.stringify(seed.updateHistory));
  }
}

function loadApplicationState() {
  partnersList = JSON.parse(localStorage.getItem('nampogogo_partners_v3')) || [];
  updateHistoryList = JSON.parse(localStorage.getItem('nampogogo_notices')) || [];
}

function initLucide() {
  if (window.lucide) {
    window.lucide.createIcons();
  }
}

// 1. Cross-Tab Real-time Synchronizer
function setupCrossTabSync() {
  window.addEventListener('storage', (e) => {
    if (e.key === 'nampogogo_partners_v3' || e.key === 'nampogogo_notices') {
      loadApplicationState();
      renderPartnersList();
      renderUpdateLogs();
      if (appMode === 'merchant') {
        renderMerchantManagementForm();
      }
      console.log("🔄 Data updated from another browser tab! UI refreshed.");
    }
  });
}

// 2. Load User Stamp Logs
function loadUserStamps() {
  if (currentUser) {
    userStamps = JSON.parse(localStorage.getItem(`nampogogo_stamps_${currentUser}`)) || [];
  } else {
    userStamps = [];
  }
}

// 3. Intro Screen & Mode Switcher
function setupIntroModeSelection() {
  const introScreen = document.getElementById('intro-screen');
  const appWorkspace = document.getElementById('app-workspace');

  const enterTouristModeBtn = document.getElementById('btn-mode-tourist');
  const enterMerchantModeBtn = document.getElementById('btn-mode-merchant');
  const quickModeSwitchBtn = document.getElementById('btn-quick-mode-switch');
  const logoHomeBtn = document.getElementById('btn-header-logo-home');
  
  if (logoHomeBtn && introScreen && appWorkspace) {
    logoHomeBtn.addEventListener('click', () => {
      introScreen.classList.remove('hidden');
      appWorkspace.classList.add('hidden');
    });
  }

  // Add click listeners as secondary backup for event bubbling
  if (enterTouristModeBtn) {
    enterTouristModeBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      window.handleModeSelect('tourist');
    });
  }

  if (enterMerchantModeBtn) {
    enterMerchantModeBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      window.handleModeSelect('merchant');
    });
  }

  if (quickModeSwitchBtn && introScreen && appWorkspace) {
    quickModeSwitchBtn.addEventListener('click', () => {
      introScreen.classList.remove('hidden');
      appWorkspace.classList.add('hidden');
    });
  }
}

// 4. Render Dynamic Top Navigation
function renderDynamicNavigationDock() {
  const navDock = document.getElementById('dynamic-nav-dock');
  if (!navDock) return;
  navDock.innerHTML = '';

  if (appMode === 'tourist') {
    navDock.innerHTML = `
      <button class="nav-btn active" data-tab="tourist-explore">
        <i data-lucide="search"></i>
        <span data-trans="explore">맛집 탐색</span>
      </button>
      <button class="nav-btn" data-tab="tourist-log">
        <i data-lucide="map"></i>
        <span data-trans="travelLog">여행 로그</span>
      </button>
      <button class="nav-btn" data-tab="tourist-profile">
        <i data-lucide="user"></i>
        <span data-trans="profile">내 정보</span>
      </button>
    `;
  } else {
    navDock.innerHTML = `
      <button class="nav-btn active" data-tab="merchant-auth">
        <i data-lucide="user-check"></i>
        <span>계정 및 제휴신청</span>
      </button>
      <button class="nav-btn" data-tab="merchant-manage" id="nav-btn-merchant-manage-lock">
        <i data-lucide="edit-3"></i>
        <span>매장 정보 올리기</span>
      </button>
    `;
  }

  const navButtons = navDock.querySelectorAll('.nav-btn');
  navButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      const targetTab = btn.getAttribute('data-tab');

      if (targetTab === 'merchant-manage') {
        if (!currentUser || currentUserRole !== 'merchant') {
          alert("⚠️ 사업자 회원가입 및 로그인 완료 후 매장 관리가 가능합니다!");
          return;
        }
        const isApproved = localStorage.getItem(`nampogogo_merchant_approved_${currentUser}`) === 'true';
        if (!isApproved) {
          alert("⚠️ 아직 공식 제휴 승인이 나지 않았습니다. [계정 및 제휴신청] 탭에서 제휴 신청을 완료해 주세요!");
          return;
        }
      }

      navButtons.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');

      switchTabPanel(targetTab);
    });
  });

  initLucide();
  updateLanguageTextsOnly();
}

function switchTabPanel(panelId) {
  activeTab = panelId;
  const panels = document.querySelectorAll('.tab-panel');
  panels.forEach(p => p.classList.remove('active'));
  
  const activePanel = document.getElementById(`tab-${panelId}`);
  if (activePanel) {
    activePanel.classList.add('active');
  }

  if (panelId === 'tourist-explore') {
    renderPartnersList();
  } else if (panelId === 'tourist-log') {
    renderTravelLog();
  } else if (panelId === 'merchant-manage') {
    renderMerchantManagementForm();
  } else if (panelId === 'merchant-auth') {
    updateMerchantAuthUI();
  }

  window.scrollTo({ top: 0, behavior: 'smooth' });
}

// 5. Multi-Language System with Real-Time Dual Dropdown Synchronization
function setupLanguage() {
  const appLangSelect = document.getElementById('app-lang-select');
  const introLangSelect = document.getElementById('intro-lang-select');
  
  if (appLangSelect) {
    appLangSelect.addEventListener('change', (e) => {
      currentLang = e.target.value;
      if (introLangSelect) introLangSelect.value = currentLang;
      updateLanguageTexts();
    });
  }

  if (introLangSelect) {
    introLangSelect.addEventListener('change', (e) => {
      currentLang = e.target.value;
      if (appLangSelect) appLangSelect.value = currentLang;
      updateLanguageTexts();
    });
  }

  updateLanguageTexts();
}

function updateLanguageTexts() {
  updateLanguageTextsOnly();
  renderPartnersList();
  renderTravelLog();
  updateAuthUIs();
  
  if (appMode === 'merchant') {
    updateMerchantAuthUI();
    renderMerchantManagementForm();
  }
}

function updateLanguageTextsOnly() {
  document.querySelectorAll('[data-trans]').forEach(element => {
    const key = element.getAttribute('data-trans');
    const txt = getTranslation(currentLang, key);
    if (txt) {
      if (element.tagName === 'INPUT' || element.tagName === 'TEXTAREA') {
        element.placeholder = txt;
      } else {
        element.textContent = txt;
      }
    }
  });
}

function getTranslation(lang, key) {
  let targetLang = lang;
  if (!translations[targetLang]) {
    if (targetLang === 'kr') targetLang = 'ko';
    if (targetLang === 'ch') targetLang = 'zh';
    if (targetLang === 'jp') targetLang = 'ja';
  }

  const keys = key.split('.');
  let obj = translations[targetLang];
  if (!obj) return null;

  for (const k of keys) {
    if (obj && obj[k] !== undefined) {
      obj = obj[k];
    } else {
      return null;
    }
  }
  return obj;
}

// 6. Global Notices Board Panel
function setupUpdatePanel() {
  const btnUpdateToggle = document.getElementById('btn-update-toggle');
  const updatePanel = document.getElementById('update-panel');

  renderUpdateLogs();

  if (btnUpdateToggle && updatePanel) {
    btnUpdateToggle.addEventListener('click', (e) => {
      e.stopPropagation();
      const isShowing = updatePanel.classList.contains('show');
      if (isShowing) {
        updatePanel.classList.remove('show');
        btnUpdateToggle.classList.remove('open');
      } else {
        updatePanel.classList.add('show');
        btnUpdateToggle.classList.add('open');
      }
    });

    document.addEventListener('click', () => {
      updatePanel.classList.remove('show');
      btnUpdateToggle.classList.remove('open');
    });
  }
}

function renderUpdateLogs() {
  const updateLogsList = document.getElementById('update-logs-list');
  if (!updateLogsList) return;
  updateLogsList.innerHTML = '';
  
  updateHistoryList.forEach(log => {
    const li = document.createElement('li');
    li.innerHTML = `<strong>${log.date}</strong>${log.content}`;
    updateLogsList.appendChild(li);
  });
}

// 7. Tourist Auth System
function setupAuthSystem() {
  const authForm = document.getElementById('nampo-auth-form');
  const btnLogout = document.getElementById('btn-action-logout');
  const btnShortcut = document.getElementById('btn-tourist-login-shortcut');

  if (authForm) {
    authForm.addEventListener('submit', (e) => {
      e.preventDefault();
      const usernameInput = document.getElementById('auth-username').value.trim();
      const passwordInput = document.getElementById('auth-password').value;
      const confirmInput = document.getElementById('auth-password-confirm').value;

      if (!usernameInput) return;

      if (passwordInput !== confirmInput) {
        alert("❌ 비밀번호와 비밀번호 확인이 다릅니다!");
        return;
      }

      let registeredUsers = JSON.parse(localStorage.getItem('nampogogo_users')) || [];
      let matchedUser = registeredUsers.find(u => u.id === usernameInput);
      
      if (matchedUser) {
        if (matchedUser.pw !== passwordInput) {
          alert("❌ 비밀번호가 올바르지 않습니다!");
          return;
        }
        currentUser = matchedUser.id;
        currentUserRole = matchedUser.role;
      } else {
        const newUser = { id: usernameInput, pw: passwordInput, role: 'visitor' };
        registeredUsers.push(newUser);
        localStorage.setItem('nampogogo_users', JSON.stringify(registeredUsers));
        
        currentUser = usernameInput;
        currentUserRole = 'visitor';
      }

      localStorage.setItem('nampogogo_user', currentUser);
      localStorage.setItem('nampogogo_user_role', currentUserRole);
      
      loadUserStamps();
      updateAuthUIs();
      authForm.reset();
      
      alert(`👋 Welcome to Nampo GoGo!\nID: ${currentUser}`);
      switchTabPanel('tourist-explore');
    });
  }

  if (btnLogout) {
    btnLogout.addEventListener('click', () => {
      currentUser = null;
      currentUserRole = 'visitor';
      userStamps = [];
      localStorage.removeItem('nampogogo_user');
      localStorage.removeItem('nampogogo_user_role');
      updateAuthUIs();
      alert("Logged out successfully.");
      switchTabPanel('tourist-explore');
    });
  }

  if (btnShortcut) {
    btnShortcut.addEventListener('click', () => {
      switchTabPanel('tourist-profile');
    });
  }

  updateAuthUIs();
}

// 100% Fail-Safe Null-Guarded Auth UI State Syncer
function updateAuthUIs() {
  const dashboardHeading = document.getElementById('user-status-heading');
  const dashboardDesc = document.getElementById('user-status-desc');
  const btnShortcut = document.getElementById('btn-tourist-login-shortcut');
  const dashboardRoleBadge = document.getElementById('dashboard-user-role');
  
  const profileUsername = document.getElementById('profile-username');
  const profileRoleBadge = document.getElementById('profile-role-badge');
  const profileAvatarEmoji = document.getElementById('profile-avatar-emoji');
  
  const authFormCard = document.getElementById('auth-form-card');
  const logoutCard = document.getElementById('logout-card');

  if (currentUser) {
    let roleTextKey = 'visitor';
    if (currentUserRole && typeof currentUserRole === 'string' && currentUserRole.length > 0) {
      roleTextKey = 'role' + currentUserRole.charAt(0).toUpperCase() + currentUserRole.slice(1);
    }
    const roleTxt = getTranslation(currentLang, roleTextKey) || currentUserRole || 'Visitor';
    
    if (dashboardHeading) dashboardHeading.textContent = currentUser;
    if (dashboardDesc) dashboardDesc.textContent = `${getTranslation(currentLang, 'welcomeUser') || 'Welcome!'}`;
    if (dashboardRoleBadge) {
      dashboardRoleBadge.textContent = roleTxt;
      dashboardRoleBadge.classList.remove('hidden');
    }
    if (btnShortcut) btnShortcut.textContent = "My Info";

    if (profileUsername) profileUsername.textContent = currentUser;
    if (profileRoleBadge) profileRoleBadge.textContent = roleTxt;
    if (authFormCard) authFormCard.classList.add('hidden');
    if (logoutCard) logoutCard.classList.remove('hidden');
    
    if (profileAvatarEmoji) {
      profileAvatarEmoji.textContent = currentUserRole === 'merchant' ? '🏢' : (currentUserRole === 'admin' ? '👑' : '👤');
    }
  } else {
    if (dashboardHeading) dashboardHeading.textContent = "Guest User";
    if (dashboardDesc) dashboardDesc.textContent = getTranslation(currentLang, 'pleaseLogin') || 'Please login.';
    if (dashboardRoleBadge) dashboardRoleBadge.classList.add('hidden');
    if (btnShortcut) btnShortcut.textContent = "Login";

    if (profileUsername) profileUsername.textContent = "Guest User";
    if (profileRoleBadge) profileRoleBadge.textContent = "Visitor";
    if (profileAvatarEmoji) profileAvatarEmoji.textContent = '👤';
    if (authFormCard) authFormCard.classList.remove('hidden');
    if (logoutCard) logoutCard.classList.add('hidden');
  }

  const stampCountEl = document.getElementById('dashboard-stamp-count');
  if (stampCountEl) {
    const listLen = userStamps ? userStamps.length : 0;
    stampCountEl.textContent = `${listLen} / 5`;
  }
}

// 8. Tourist Food Board category filtering & sorting
function renderPartnersList() {
  const container = document.getElementById('delivery-partners-container');
  if (!container) return;
  container.innerHTML = '';

  let filtered = [...partnersList];
  if (activeSubcatFilter !== 'all') {
    filtered = filtered.filter(p => p.subCategory === activeSubcatFilter);
  }

  // Multi-sorting algorithm
  filtered.sort((a, b) => {
    const partnerA = a.isPartner ? 1 : 0;
    const partnerB = b.isPartner ? 1 : 0;
    if (partnerA !== partnerB) {
      return partnerB - partnerA;
    }

    if (a.isPartner && b.isPartner) {
      const mediaCountA = (a.gallery && Array.isArray(a.gallery) ? a.gallery.length : 0) + 1;
      const mediaCountB = (b.gallery && Array.isArray(b.gallery) ? b.gallery.length : 0) + 1;
      if (mediaCountA !== mediaCountB) {
        return mediaCountB - mediaCountA;
      }
      if (a.rating !== b.rating) {
        return b.rating - a.rating;
      }
      const videoCountA = (a.gallery && Array.isArray(a.gallery)) ? a.gallery.filter(g => g.type === 'video').length : 0;
      const videoCountB = (b.gallery && Array.isArray(b.gallery)) ? b.gallery.filter(g => g.type === 'video').length : 0;
      if (videoCountA !== videoCountB) {
        return videoCountB - videoCountA;
      }
      const imgCountA = (a.gallery && Array.isArray(a.gallery)) ? a.gallery.filter(g => g.type === 'image').length : 0;
      const imgCountB = (b.gallery && Array.isArray(b.gallery)) ? b.gallery.filter(g => g.type === 'image').length : 0;
      return imgCountB - imgCountA;
    } else {
      return b.rating - a.rating;
    }
  });

  if (filtered.length === 0) {
    container.innerHTML = `<div class="empty-log-state"><p>이 카테고리에 해당하는 매장이 없습니다.</p></div>`;
    return;
  }

  filtered.forEach(p => {
    const card = document.createElement('div');
    card.className = `delivery-partner-card ${p.isPartner ? 'is-partner-gold' : ''}`;
    
    const mediaTotal = (p.gallery && Array.isArray(p.gallery) ? p.gallery.length : 0) + 1;

    card.innerHTML = `
      <div class="delivery-card-thumb" style="background-image: url('${p.image}')">
        ${p.isPartner ? `<span class="delivery-card-partner-badge">제휴사</span>` : ''}
      </div>
      <div class="delivery-card-info">
        <div class="delivery-card-title-row">
          <h3>${p.name[currentLang] || p.name['en']}</h3>
          <div class="delivery-card-rating">
            <i data-lucide="star"></i> ${p.rating.toFixed(1)}
          </div>
        </div>
        <div class="delivery-card-benefit-snippet">
          🎁 ${p.benefits[currentLang] || p.benefits['en']}
        </div>
        <div class="delivery-card-footer">
          <span>📍 거리: <strong>${p.distanceValue}</strong> | 미디어: <strong>${mediaTotal}개</strong></span>
          <strong>${getTranslation(currentLang, 'sub' + p.subCategory.charAt(0).toUpperCase() + p.subCategory.slice(1)) || p.subCategory}</strong>
        </div>
      </div>
    `;

    card.addEventListener('click', () => openPartnerDetail(p.id));
    container.appendChild(card);
  });

  initLucide();
  setupSubcatGridClickHandlers();
}

function setupSubcatGridClickHandlers() {
  document.querySelectorAll('.delivery-cat-btn').forEach(item => {
    const newEl = item.cloneNode(true);
    item.parentNode.replaceChild(newEl, item);

    newEl.addEventListener('click', () => {
      document.querySelectorAll('.delivery-cat-btn').forEach(el => el.classList.remove('active'));
      newEl.classList.add('active');
      activeSubcatFilter = newEl.getAttribute('data-subcat');
      renderPartnersList();
    });
  });
}

// 9. Partner Detail Modal
function openPartnerDetail(id) {
  const p = partnersList.find(item => item.id === id);
  if (!p) return;

  const contentWrap = document.getElementById('partner-modal-body-content');
  if (!contentWrap) return;

  const isStamped = userStamps ? userStamps.some(s => s.partnerId === p.id) : false;
  const isKorean = currentLang === 'kr';
  const directionLink = isKorean ? p.mapLinkNaver : p.mapLinkGoogle;

  let mediaSwiperMarkup = '';
  mediaSwiperMarkup += `<div class="detail-gallery-img" style="background-image: url('${p.image}')"></div>`;
  if (p.gallery && Array.isArray(p.gallery) && p.gallery.length > 0) {
    p.gallery.forEach(file => {
      if (file.type === 'video' || file.data.startsWith('data:video/')) {
        mediaSwiperMarkup += `<video class="detail-gallery-video" controls src="${file.data}"></video>`;
      } else {
        mediaSwiperMarkup += `<div class="detail-gallery-img" style="background-image: url('${file.data}')"></div>`;
      }
    });
  }

  let pricingRows = '';
  if (p.priceList && Array.isArray(p.priceList)) {
    p.priceList.forEach(item => {
      pricingRows += `
        <tr>
          <td>${item.name[currentLang] || item.name['en']}</td>
          <td class="price-col">${item.price}</td>
        </tr>
      `;
    });
  }

  const langBadgeStr = (p.menuForeign && p.menuForeign[currentLang]) ? `<span class="characteristic-badge badge-blue">다국어 대응</span>` : '';
  const parkingStr = p.parking ? `<span class="characteristic-badge badge-secondary">🚗 주차: ${p.parking}</span>` : '';
  
  let paymentBadgeStr = '';
  if (p.payments && Array.isArray(p.payments) && p.payments.length > 0) {
    p.payments.forEach(pay => {
      paymentBadgeStr += `<span class="characteristic-badge badge-warning">💳 ${pay}</span>`;
    });
  }

  let reviewsMarkup = '';
  if (!p.reviews || !Array.isArray(p.reviews) || p.reviews.length === 0) {
    reviewsMarkup = `<p class="empty-state text-center">${getTranslation(currentLang, 'noReviews') || 'No reviews yet.'}</p>`;
  } else {
    p.reviews.forEach(rev => {
      reviewsMarkup += `
        <div class="review-item">
          <div class="review-user-row">
            <span>👤 ${rev.username}</span>
            <span class="text-warning">★ ${rev.rating.toFixed(1)}</span>
          </div>
          <p>${rev.content[currentLang] || rev.content['en']}</p>
        </div>
      `;
    });
  }

  let writerMarkup = '';
  if (currentUser) {
    if (isStamped) {
      writerMarkup = `
        <div class="review-writer-box">
          <h5 style="font-size:11px; margin-bottom:8px; font-weight:800;">✍️ Write Verified Review</h5>
          <div class="writer-rating-select">
            <span data-trans="ratingLabel">${getTranslation(currentLang, 'ratingLabel') || 'Rating'}</span>
            <select id="review-rating-select">
              <option value="5">★ 5.0</option>
              <option value="4">★ 4.0</option>
              <option value="3">★ 3.0</option>
              <option value="2">★ 2.0</option>
              <option value="1">★ 1.0</option>
            </select>
          </div>
          <textarea id="review-comment-textarea" class="writer-textarea" rows="2" placeholder="${getTranslation(currentLang, 'reviewInputPlaceholder') || 'Write review here...'}"></textarea>
          <button class="btn btn-primary btn-sm btn-block" id="btn-submit-review-act">${getTranslation(currentLang, 'reviewBtn') || 'Submit'}</button>
        </div>
      `;
    } else {
      writerMarkup = `
        <div class="glass-box text-center" style="margin-top: 16px; border-color: var(--accent); padding: 10px;">
          <p class="review-alert-msg" data-trans="reviewAuthError">${getTranslation(currentLang, 'reviewAuthError') || 'Verified stamps required.'}</p>
        </div>
      `;
    }
  } else {
    writerMarkup = `
      <div class="glass-box text-center" style="margin-top: 16px; padding: 10px;">
        <p class="review-alert-msg" style="color:var(--text-muted);">Please Login & scan QR code to write review.</p>
      </div>
    `;
  }

  const sc = p.scores || { hygiene: 4.8, taste: 4.8, service: 4.8, cleanliness: 4.8 };

  contentWrap.innerHTML = `
    <!-- Horizontal Swipe Media Gallery -->
    <div class="modal-detail-media-scroller">
      ${mediaSwiperMarkup}
    </div>

    <!-- Title and Rating -->
    <div class="modal-detail-title-row">
      <h3>${p.name[currentLang] || p.name['en']}</h3>
      <div class="rating-badge"><i data-lucide="star"></i> ${p.rating.toFixed(1)}</div>
    </div>

    <!-- Address, Phone & Map link -->
    <div class="modal-detail-address-block">
      <div>📍 주소: <span class="address-val-text">${p.address[currentLang] || p.address['en']}</span></div>
      <div style="margin-top: 4px;">📞 연락처: <a href="tel:${p.phone}" class="address-val-text" style="color:var(--primary); text-decoration:underline;">${p.phone}</a></div>
      <div style="margin-top: 4px;">🕒 영업시간: <span class="address-val-text">${p.hours}</span></div>
      
      <div class="direction-btn-row">
        <button class="btn btn-primary btn-dir-navigation" onclick="window.open('${directionLink}', '_blank')">
          <i data-lucide="navigation" style="width:10px; height:10px;"></i> ${getTranslation(currentLang, 'getDirection') || 'Route'} (${p.distanceValue})
        </button>
      </div>
    </div>

    <!-- Store Characteristics Badges -->
    <div class="store-characteristics-wrap">
      ${langBadgeStr}
      ${parkingStr}
      ${paymentBadgeStr}
      <span class="characteristic-badge badge-accent">⚡ 주문: QR/대면</span>
    </div>

    <!-- Accordion detailed rating -->
    <div class="rating-accordion-header" id="btn-rating-accordion-toggle">
      <span>📊 Google-style 세부 항목 평점 요약</span>
      <i data-lucide="chevron-down"></i>
    </div>
    <div class="rating-accordion-content">
      <div class="rating-metric-bar-row">
        <span class="rating-metric-label">위생도</span>
        <div class="metric-bar-bg"><div class="metric-bar-fill" style="width: ${sc.hygiene * 20}%"></div></div>
        <span class="metric-score-val">${sc.hygiene.toFixed(1)}</span>
      </div>
      <div class="rating-metric-bar-row">
        <span class="rating-metric-label">맛/품질</span>
        <div class="metric-bar-bg"><div class="metric-bar-fill" style="width: ${sc.taste * 20}%"></div></div>
        <span class="metric-score-val">${sc.taste.toFixed(1)}</span>
      </div>
      <div class="rating-metric-bar-row">
        <span class="rating-metric-label">서비스</span>
        <div class="metric-bar-bg"><div class="metric-bar-fill" style="width: ${sc.service * 20}%"></div></div>
        <span class="metric-score-val">${sc.service.toFixed(1)}</span>
      </div>
      <div class="rating-metric-bar-row">
        <span class="rating-metric-label">청결도</span>
        <div class="metric-bar-bg"><div class="metric-bar-fill" style="width: ${sc.cleanliness * 20}%"></div></div>
        <span class="metric-score-val">${sc.cleanliness.toFixed(1)}</span>
      </div>
    </div>

    <!-- Modal Tab buttons -->
    <div class="modal-tabs-nav" style="margin-top: 14px;">
      <button class="modal-tab-btn active" data-tab-panel="modal-panel-info">Introduction</button>
      <button class="modal-tab-btn" data-tab-panel="modal-panel-pricing">Menu Price List</button>
      <button class="modal-tab-btn" data-tab-panel="modal-panel-seo">SEO Crawler Tag</button>
    </div>

    <!-- TAB PANEL 1: Info -->
    <div class="modal-tab-panel active" id="modal-panel-info">
      <div class="benefit-strip" style="background:var(--primary-soft); padding:10px; border-radius:8px;">
        <h5 style="font-size:10px; font-weight:800; color:var(--primary);">${getTranslation(currentLang, 'benefitTitle') || 'Benefits'}</h5>
        <p style="font-size:11px; margin-top:2px;">${p.benefits[currentLang] || p.benefits['en']}</p>
      </div>
    </div>

    <!-- TAB PANEL 2: Pricing & Menu -->
    <div class="modal-tab-panel" id="modal-panel-pricing">
      <div class="glass-box" style="padding:12px; margin-bottom:12px;">
        <table class="pricing-table">
          <tbody>
            ${pricingRows}
          </tbody>
        </table>
        
        <div style="border-top:1px dashed rgba(0,0,0,0.06); margin-top:10px; padding-top:8px;">
          <span style="font-size:8px; font-weight:800; color:var(--primary); text-transform:uppercase;">🌐 Foreign Language Menu (외국어 메뉴판)</span>
          <p style="font-size:10px; color:var(--text-body); margin-top:4px; font-style:italic;">"${p.menuForeign[currentLang] || p.menuForeign['en']}"</p>
        </div>
      </div>
    </div>

    <!-- TAB PANEL 3: SEO -->
    <div class="modal-tab-panel" id="modal-panel-seo">
      <div class="seo-info-box" style="background:var(--primary-soft); padding:12px; border-radius:6px; font-size:10px;">
        <div class="seo-tag-item"><strong>&lt;title&gt;</strong> ${p.name[currentLang] || p.name['en']} | Nampo GoGo Busan</div>
        <div class="seo-tag-item" style="margin-top:6px;"><strong>&lt;meta name="description"&gt;</strong> ${p.seoDescription}</div>
        <div class="seo-tag-item" style="margin-top:6px;"><strong>&lt;meta name="keywords"&gt;</strong> ${p.seoKeywords}</div>
      </div>
    </div>

    <button class="btn btn-secondary btn-block" id="btn-trigger-qr-scan" style="margin-top: 14px;">
      <i data-lucide="scan-line"></i> 
      <span>${isStamped ? (getTranslation(currentLang, 'alreadyStamped') || 'Stamped') : (getTranslation(currentLang, 'scanBtnText') || 'Scan QR')}</span>
    </button>

    <div class="reviews-section">
      <h4 data-trans="reviewTitle">${getTranslation(currentLang, 'reviewTitle') || 'Reviews'}</h4>
      <div id="modal-reviews-list">
        ${reviewsMarkup}
      </div>
      ${writerMarkup}
    </div>
  `;

  if (partnerDetailModal) {
    partnerDetailModal.classList.add('active');
  }
  initLucide();

  const accordionHeader = document.getElementById('btn-rating-accordion-toggle');
  if (accordionHeader) {
    accordionHeader.addEventListener('click', () => {
      accordionHeader.classList.toggle('open');
    });
  }

  setupModalTabs();

  const qrBtn = document.getElementById('btn-trigger-qr-scan');
  if (qrBtn) {
    if (isStamped) qrBtn.setAttribute('disabled', 'true');
    qrBtn.addEventListener('click', () => {
      if (!currentUser) {
        alert("Please login first to check-in.");
        if (partnerDetailModal) partnerDetailModal.classList.remove('active');
        switchTabPanel('tourist-profile');
        return;
      }
      if (partnerDetailModal) partnerDetailModal.classList.remove('active');
      triggerQRScanner(p.id);
    });
  }

  const btnSubmitReview = document.getElementById('btn-submit-review-act');
  if (btnSubmitReview && currentUser && isStamped) {
    btnSubmitReview.addEventListener('click', () => {
      const rating = parseInt(document.getElementById('review-rating-select').value);
      const text = document.getElementById('review-comment-textarea').value.trim();

      if (!text) {
        alert("Please write a short review content.");
        return;
      }

      const reviewObj = {
        username: currentUser,
        rating: rating,
        content: { kr: text, en: text, ch: text, jp: text }
      };

      if (!p.reviews) p.reviews = [];
      p.reviews.unshift(reviewObj);

      const sum = p.reviews.reduce((acc, cur) => acc + cur.rating, 0);
      p.rating = sum / p.reviews.length;

      savePartnersToStorage();
      alert("Verified review posted successfully!");
      openPartnerDetail(p.id);
    });
  }
}

function savePartnersToStorage() {
  localStorage.setItem('nampogogo_partners_v3', JSON.stringify(partnersList));
}

function setupModalTabs() {
  const tabs = document.querySelectorAll('.modal-tab-btn');
  const panels = document.querySelectorAll('.modal-tab-panel');

  tabs.forEach(tab => {
    tab.addEventListener('click', () => {
      tabs.forEach(t => t.classList.remove('active'));
      tab.classList.add('active');

      const targetPanel = tab.getAttribute('data-tab-panel');
      panels.forEach(panel => {
        panel.classList.remove('active');
        if (panel.id === targetPanel) {
          panel.classList.add('active');
        }
      });
    });
  });
}

// 10. QR Scan
let targetQrPartnerId = null;

function triggerQRScanner(partnerId) {
  targetQrPartnerId = partnerId;
  const p = partnersList.find(item => item.id === partnerId);
  if (!p) return;

  const now = new Date();
  const dateStr = now.toLocaleDateString();
  const timeStr = now.toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit' });

  const ticketDate = document.getElementById('stamp-card-date');
  const ticketTime = document.getElementById('stamp-card-time');
  const rewardTxt = document.getElementById('qr-reward-text');

  if (ticketDate) ticketDate.textContent = dateStr;
  if (ticketTime) ticketTime.textContent = timeStr;
  if (rewardTxt) rewardTxt.textContent = p.benefits[currentLang] || p.benefits['en'];
  
  const successScreen = document.getElementById('qr-success-screen');
  if (successScreen) successScreen.classList.add('hidden');
  
  if (qrScannerModal) {
    qrScannerModal.classList.add('active');
  }

  setTimeout(() => {
    if (successScreen) successScreen.classList.remove('hidden');
  }, 2200);
}

function setupInteractiveScans() {
  const confirmBtn = document.getElementById('btn-claim-stamp-confirm');
  if (confirmBtn) {
    confirmBtn.addEventListener('click', () => {
      if (!targetQrPartnerId) return;

      const p = partnersList.find(item => item.id === targetQrPartnerId);
      if (!p) return;

      const now = new Date();
      const dateStr = now.toLocaleDateString();
      const timeStr = now.toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit' });

      if (!userStamps) userStamps = [];
      const index = userStamps.findIndex(s => s.partnerId === p.id);
      let visitCount = 1;
      
      if (index !== -1) {
        visitCount = userStamps[index].count + 1;
        userStamps[index].timestamp = timeStr;
        userStamps[index].date = dateStr;
        userStamps[index].count = visitCount;
      } else {
        userStamps.push({
          partnerId: p.id,
          partnerName: p.name['kr'],
          timestamp: timeStr,
          date: dateStr,
          count: 1,
          isPartner: p.isPartner,
          visitorId: currentUser,
          storeId: p.id,
          memo: ""
        });
      }

      localStorage.setItem(`nampogogo_stamps_${currentUser}`, JSON.stringify(userStamps));
      
      updateAuthUIs();
      renderTravelLog();

      if (qrScannerModal) qrScannerModal.classList.remove('active');
      alert(`👣 Visit Stamp Saved!\nStore: ${p.name[currentLang] || p.name['en']}\nBenefit Status: Certified ✔`);
    });
  }
}

// 11. Travel Log
function renderTravelLog() {
  const stampGrid = document.getElementById('stamp-indicator-grid');
  const timeline = document.getElementById('travel-log-timeline');
  const logCountNum = document.getElementById('log-count-num');
  const emptyMsg = document.getElementById('log-empty-msg');
  const actionsBar = document.getElementById('log-actions-bar');

  if (!stampGrid || !timeline) return;

  stampGrid.innerHTML = '';
  for (let i = 0; i < 5; i++) {
    const node = document.createElement('div');
    node.className = 'stamp-node';
    if (userStamps && userStamps[i]) {
      node.classList.add('active');
      node.innerHTML = '👣';
    } else {
      node.innerHTML = `${i + 1}`;
    }
    stampGrid.appendChild(node);
  }

  if (logCountNum) logCountNum.textContent = userStamps ? userStamps.length : 0;

  const oldNodes = timeline.querySelectorAll('.timeline-node');
  oldNodes.forEach(n => n.remove());

  if (!userStamps || userStamps.length === 0) {
    if (emptyMsg) emptyMsg.classList.remove('hidden');
    if (actionsBar) actionsBar.classList.add('hidden');
    timeline.classList.remove('active');
  } else {
    if (emptyMsg) emptyMsg.classList.add('hidden');
    if (actionsBar) actionsBar.classList.remove('hidden');
    timeline.classList.add('active');

    userStamps.forEach((stamp, idx) => {
      const p = partnersList.find(item => item.id === stamp.partnerId);
      if (!p) return;

      const nodeEl = document.createElement('div');
      nodeEl.className = 'timeline-node';
      nodeEl.innerHTML = `
        <div class="timeline-icon-dot"></div>
        <div class="timeline-card-box">
          <h4>${idx + 1}. ${p.name[currentLang] || p.name['en']}</h4>
          <p>🎁 Benefit: ${p.benefits[currentLang] || p.benefits['en']}</p>
          <span class="timeline-time-badge">🕒 Verified at ${stamp.timestamp} (Visits: ${stamp.count})</span>
          
          <!-- Memo Box -->
          <div class="travel-memo-wrap">
            <label data-trans="memoLabel">${getTranslation(currentLang, 'memoLabel') || 'Memo'}</label>
            <textarea id="memo-input-${stamp.partnerId}" rows="2" placeholder="${getTranslation(currentLang, 'memoPlaceholder') || 'Enter memo...'}">${stamp.memo || ''}</textarea>
            <button class="btn btn-secondary btn-sm btn-block btn-save-memo" data-id="${stamp.partnerId}">
              <i data-lucide="save" style="width:10px; height:10px;"></i> 
              <span data-trans="memoSaveBtn">${getTranslation(currentLang, 'memoSaveBtn') || 'Save'}</span>
            </button>
          </div>
        </div>
      `;

      nodeEl.querySelector('.btn-save-memo').addEventListener('click', (e) => {
        const pId = e.currentTarget.getAttribute('data-id');
        const textVal = document.getElementById(`memo-input-${pId}`).value.trim();
        
        const stampObj = userStamps.find(s => s.partnerId === pId);
        if (stampObj) {
          stampObj.memo = textVal;
          localStorage.setItem(`nampogogo_stamps_${currentUser}`, JSON.stringify(userStamps));
          alert(getTranslation(currentLang, 'memoSavedSuccess') || 'Memo saved.');
        }
      });

      timeline.appendChild(nodeEl);
    });

    initLucide();
    const exportBtn = document.getElementById('btn-export-log-card');
    if (exportBtn) exportBtn.onclick = openSNSCardModal;
  }
}

function openSNSCardModal() {
  const storyStampList = document.getElementById('story-stamp-list');
  const storyUserTag = document.getElementById('story-user-tag');
  
  if (storyUserTag) storyUserTag.textContent = `@${currentUser || 'Explorer'}`;
  if (storyStampList && userStamps) {
    storyStampList.innerHTML = '';
    userStamps.forEach((stamp, idx) => {
      const p = partnersList.find(item => item.id === stamp.partnerId);
      if (!p) return;
      
      const node = document.createElement('div');
      node.className = 'story-log-node';
      const memoSnippet = stamp.memo ? `<br><span style="font-size:8px; opacity:0.8; font-style:italic;">"${stamp.memo}"</span>` : '';
      node.innerHTML = `🌟 Day Route ${idx + 1}<br><strong>${p.name[currentLang] || p.name['en']}</strong>${memoSnippet}`;
      storyStampList.appendChild(node);
    });
  }

  if (logSnsModal) logSnsModal.classList.add('active');

  const btnCopyCaption = document.getElementById('btn-copy-sns-caption');
  if (btnCopyCaption) {
    btnCopyCaption.onclick = () => {
      if (!userStamps) return;
      const routeText = userStamps.map((stamp, idx) => {
        const p = partnersList.find(item => item.id === stamp.partnerId);
        const memoText = stamp.memo ? ` (${stamp.memo})` : '';
        return `${idx + 1}. ${p ? p.name[currentLang] : ''}${memoText}`;
      }).join('\n➔ ');

      const instagramText = `🔥 My Nampo GoGo Travel Footprints!\n👣 Today's route:\n${routeText}\n📍 Verified stamps collected at Nampodong, Busan.\n#NampoGoGo #BusanTour #Nampodong #BusanTravel #KLounge`;
      
      navigator.clipboard.writeText(instagramText).then(() => {
        alert(getTranslation(currentLang, 'snsSuccess') || 'Copied to clipboard.');
      });
    };
  }

  const btnDownloadCard = document.getElementById('btn-download-sns-card');
  if (btnDownloadCard) {
    btnDownloadCard.onclick = () => {
      alert("📸 Story Card Template Image downloaded successfully (Simulation)!");
    };
  }
}

// 12. Merchant Control System
function setupMerchantSystem() {
  const joinForm = document.getElementById('merchant-join-form');
  const applyForm = document.getElementById('merchant-apply-form');
  const mediaFileInput = document.getElementById('merchant-media-files');
  const storeSaveBtn = document.getElementById('btn-save-store-complete');

  if (joinForm) {
    joinForm.addEventListener('submit', (e) => {
      e.preventDefault();
      const usernameInput = document.getElementById('m-auth-username').value.trim();
      const passwordInput = document.getElementById('m-auth-password').value;
      const confirmInput = document.getElementById('m-auth-password-confirm').value;

      if (!usernameInput) return;

      if (passwordInput !== confirmInput) {
        alert("❌ 비밀번호와 비밀번호 확인이 서로 다릅니다!");
        return;
      }

      let registeredUsers = JSON.parse(localStorage.getItem('nampogogo_users')) || [];
      let matchedUser = registeredUsers.find(u => u.id === usernameInput);
      
      if (matchedUser) {
        if (matchedUser.pw !== passwordInput) {
          alert("❌ 비밀번호가 올바르지 않습니다!");
          return;
        }
        currentUser = matchedUser.id;
        currentUserRole = matchedUser.role;
      } else {
        const newUser = { id: usernameInput, pw: passwordInput, role: 'merchant' };
        registeredUsers.push(newUser);
        localStorage.setItem('nampogogo_users', JSON.stringify(registeredUsers));
        
        currentUser = usernameInput;
        currentUserRole = 'merchant';
      }

      localStorage.setItem('nampogogo_user', currentUser);
      localStorage.setItem('nampogogo_user_role', currentUserRole);
      
      updateMerchantAuthUI();
      alert(`💼 사업자 모드 가입/로그인 완료!\nID: ${currentUser}`);
    });
  }

  if (applyForm) {
    applyForm.addEventListener('submit', (e) => {
      e.preventDefault();
      if (!currentUser) return;

      const addr = document.getElementById('apply-address').value.trim();
      const subcat = document.getElementById('apply-subcategory').value;
      const phoneVal = document.getElementById('apply-phone').value.trim();

      localStorage.setItem(`nampogogo_merchant_approved_${currentUser}`, 'true');
      localStorage.setItem(`nampogogo_merchant_addr_${currentUser}`, addr);
      localStorage.setItem(`nampogogo_merchant_subcat_${currentUser}`, subcat);
      localStorage.setItem(`nampogogo_merchant_phone_${currentUser}`, phoneVal);

      const storeId = currentUser.toLowerCase().replace('owner_', 'partner_');
      let storeObj = partnersList.find(p => p.id === storeId);
      
      if (!storeObj) {
        storeObj = {
          id: storeId,
          name: { kr: `${currentUser} 매장`, en: `${currentUser} Store`, ch: `${currentUser} 铺`, jp: `${currentUser} 店` },
          category: (subcat === 'massage' || subcat === 'cafe') ? subcat : 'food',
          subCategory: subcat,
          isPartner: true,
          image: "https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=400&q=80",
          gallery: [],
          rating: 5.0,
          scores: { hygiene: 5.0, taste: 5.0, service: 5.0, cleanliness: 5.0 },
          posX: 129.034789,
          posY: 35.097489,
          mapLinkNaver: `https://map.naver.com/v5/directions/14363294,35.097489,내위치,,/14363310,35.098222,목적지,,/walk`,
          mapLinkGoogle: `https://www.google.com/maps/dir/?api=1&origin=35.097489,129.034789&destination=35.098222,129.035789&travelmode=walking`,
          distanceValue: "100m",
          address: { kr: addr, en: addr, ch: addr, jp: addr },
          phone: phoneVal,
          hours: "11:00 - 22:00",
          priceList: [],
          menuForeign: { kr: "외국어 메뉴판 구비", en: "English Menu", ch: "中文菜单", jp: "日本語メニュー" },
          benefits: { kr: "제휴 혜택 제공", en: "Exclusive benefit", ch: "合作福利", jp: "提携特典" },
          seoDescription: `${currentUser} 제휴 매장`,
          seoKeywords: `남포동 ${currentUser}`,
          reviews: [],
          payments: ["신용카드", "삼성페이"],
          parking: "유"
        };
        partnersList.unshift(storeObj);
        savePartnersToStorage();
      }

      alert("🎉 서류 심사 즉시 통과! Nampo GoGo 공식 제휴 매장으로 승인되었습니다!");
      
      renderDynamicNavigationDock();
      updateMerchantAuthUI();
      switchTabPanel('merchant-manage');
    });
  }

  if (mediaFileInput) {
    mediaFileInput.addEventListener('change', (e) => {
      const files = e.target.files;
      const previewContainer = document.getElementById('merchant-media-previews');
      if (!previewContainer) return;

      previewContainer.innerHTML = '';
      tempUploadedMedia = [];

      Array.from(files).forEach((file, index) => {
        const reader = new FileReader();
        reader.onload = (event) => {
          const base64Data = event.target.result;
          const isVideo = file.type.startsWith('video/');

          tempUploadedMedia.push({
            type: isVideo ? 'video' : 'image',
            data: base64Data
          });

          const pBox = document.createElement('div');
          pBox.className = `preview-thumb-box ${isVideo ? 'video' : ''}`;
          pBox.style.backgroundImage = isVideo ? 'none' : `url('${base64Data}')`;
          
          const radio = document.createElement('input');
          radio.type = 'radio';
          radio.name = 'merchant-thumb-select';
          radio.value = index;
          if (index === 0) {
            radio.checked = true;
            selectedThumbnailBase64 = base64Data;
          }
          
          radio.addEventListener('change', () => {
            selectedThumbnailBase64 = base64Data;
          });

          pBox.appendChild(radio);
          previewContainer.appendChild(pBox);
        };
        reader.readAsDataURL(file);
      });
    });
  }

  if (storeSaveBtn) {
    storeSaveBtn.addEventListener('click', (e) => {
      e.preventDefault();
      
      const hasSignboard = document.getElementById('check-media-signboard').checked;
      const hasMenu = document.getElementById('check-media-menu').checked;
      const hasInside = document.getElementById('check-media-inside').checked;
      const hasOutside = document.getElementById('check-media-outside').checked;

      if (!hasSignboard || !hasMenu || !hasInside || !hasOutside) {
        alert("⚠️ [업로드 필수 조건 미달]\n대문(간판) 사진, 메뉴판 사진, 내부 사진 2장 이상, 외부 전경 사진 2장 이상이 모두 포함되어 있는지 확인하시고 체크박스에 체크해 주셔야 최종 올리기가 가능합니다!");
        return;
      }

      const store = findMerchantStore();
      if (!store) {
        alert("오류: 매장 정보를 찾을 수 없습니다.");
        return;
      }

      store.benefits[currentLang] = document.getElementById('edit-benefit-input').value.trim();
      store.hours = document.getElementById('edit-hours-input').value.trim();
      store.phone = document.getElementById('edit-phone-input').value.trim();
      
      const sigName = document.getElementById('menu-sig-name').value.trim();
      const sigPrice = document.getElementById('menu-sig-price').value.trim();
      const stdName = document.getElementById('menu-std-name').value.trim();
      const stdPrice = document.getElementById('menu-std-price').value.trim();
      const seaName = document.getElementById('menu-sea-name').value.trim();
      const seaPrice = document.getElementById('menu-sea-price').value.trim();

      store.priceList = [];
      if (sigName) store.priceList.push({ name: { kr: sigName, en: sigName, ch: sigName, jp: sigName }, price: sigPrice });
      if (stdName) store.priceList.push({ name: { kr: stdName, en: stdName, ch: stdName, jp: stdName }, price: stdPrice });
      if (seaName) store.priceList.push({ name: { kr: seaName, en: seaName, ch: seaName, jp: seaName }, price: seaPrice });

      store.parking = document.querySelector('input[name="m-parking-status"]:checked').value;

      const selectedPayments = Array.from(document.querySelectorAll('input[name="m-payment-methods"]:checked')).map(el => el.value);
      store.payments = selectedPayments;

      if (tempUploadedMedia.length > 0) {
        store.gallery = tempUploadedMedia;
        if (selectedThumbnailBase64) {
          store.image = selectedThumbnailBase64;
        }
      }

      savePartnersToStorage();
      alert("🎉 매장 상세 메뉴 및 미디어가 성공적으로 플랫폼에 게시 및 노출 순위 갱신 완료되었습니다!");
      
      appMode = 'tourist';
      renderDynamicNavigationDock();
      switchTabPanel('tourist-explore');
    });
  }
}

function updateMerchantAuthUI() {
  const loginCard = document.getElementById('merchant-login-card');
  const applyCard = document.getElementById('merchant-apply-card');
  const approvedCard = document.getElementById('merchant-approved-status-card');

  if (loginCard) loginCard.classList.add('hidden');
  if (applyCard) applyCard.classList.add('hidden');
  if (approvedCard) approvedCard.classList.add('hidden');

  if (!currentUser || currentUserRole !== 'merchant') {
    if (loginCard) loginCard.classList.remove('hidden');
  } else {
    const isApproved = localStorage.getItem(`nampogogo_merchant_approved_${currentUser}`) === 'true';
    if (isApproved) {
      if (approvedCard) approvedCard.classList.remove('hidden');
    } else {
      if (applyCard) applyCard.classList.remove('hidden');
    }
  }
}

function findMerchantStore() {
  if (!currentUser || currentUserRole !== 'merchant') return null;
  const storeId = currentUser.toLowerCase().replace('owner_', 'partner_');
  return partnersList.find(p => p.id === storeId) || partnersList[0];
}

function renderMerchantManagementForm() {
  const store = findMerchantStore();
  if (!store) return;

  const benefitInput = document.getElementById('edit-benefit-input');
  const hoursInput = document.getElementById('edit-hours-input');
  const phoneInput = document.getElementById('edit-phone-input');

  if (benefitInput) benefitInput.value = store.benefits[currentLang] || store.benefits['en'] || '';
  if (hoursInput) hoursInput.value = store.hours || '11:00 - 22:00';
  if (phoneInput) phoneInput.value = store.phone || '+82-51-111-2222';

  const sigNameInput = document.getElementById('menu-sig-name');
  const sigPriceInput = document.getElementById('menu-sig-price');
  const stdNameInput = document.getElementById('menu-std-name');
  const stdPriceInput = document.getElementById('menu-std-price');
  const seaNameInput = document.getElementById('menu-sea-name');
  const seaPriceInput = document.getElementById('menu-sea-price');

  if (sigNameInput && sigPriceInput) {
    if (store.priceList && store.priceList[0]) {
      sigNameInput.value = store.priceList[0].name[currentLang] || store.priceList[0].name['en'];
      sigPriceInput.value = store.priceList[0].price;
    } else {
      sigNameInput.value = ''; sigPriceInput.value = '';
    }
  }

  if (stdNameInput && stdPriceInput) {
    if (store.priceList && store.priceList[1]) {
      stdNameInput.value = store.priceList[1].name[currentLang] || store.priceList[1].name['en'];
      stdPriceInput.value = store.priceList[1].price;
    } else {
      stdNameInput.value = ''; stdPriceInput.value = '';
    }
  }

  if (seaNameInput && seaPriceInput) {
    if (store.priceList && store.priceList[2]) {
      seaNameInput.value = store.priceList[2].name[currentLang] || store.priceList[2].name['en'];
      seaPriceInput.value = store.priceList[2].price;
    } else {
      seaNameInput.value = ''; seaPriceInput.value = '';
    }
  }

  const parkVal = store.parking || '유';
  document.querySelectorAll('input[name="m-parking-status"]').forEach(radio => {
    radio.checked = radio.value === parkVal;
  });

  const pays = store.payments || ["신용카드", "삼성페이"];
  document.querySelectorAll('input[name="m-payment-methods"]').forEach(box => {
    box.checked = pays.includes(box.value);
  });

  let stampCount = 0;
  for (let i = 0; i < localStorage.length; i++) {
    const key = localStorage.key(i);
    if (key.startsWith('nampogogo_stamps_')) {
      const stamps = JSON.parse(localStorage.getItem(key)) || [];
      stamps.forEach(s => {
        if (s.partnerId === store.id) stampCount += s.count;
      });
    }
  }
  const stampCountEl = document.getElementById('merchant-stamps-val');
  if (stampCountEl) stampCountEl.textContent = `${stampCount}건`;
}

// AI Course Planner Logic
function setupAIPlanner() {
  const btnPlanner = document.getElementById('btn-run-ai-recommend');
  const outputArea = document.getElementById('ai-course-output-area');
  const shortcutBtn = document.getElementById('btn-shortcut-ai-planner');
  const plannerForm = document.getElementById('ai-planner-modal-content-area');

  if (shortcutBtn) {
    shortcutBtn.addEventListener('click', () => {
      if (plannerForm) plannerForm.classList.toggle('hidden');
    });
  }

  if (btnPlanner && outputArea) {
    btnPlanner.addEventListener('click', () => {
      const selectedActs = Array.from(document.querySelectorAll('input[name="ai-activities"]:checked')).map(el => el.value);
      const budgetVal = parseInt(document.getElementById('ai-budget-select').value);

      if (selectedActs.length === 0) {
        alert("하고 싶은 활동을 최소 1개 이상 선택해 주세요!");
        return;
      }

      outputArea.innerHTML = '';
      outputArea.classList.remove('hidden');

      let courseRoutes = [];

      const kLounge = partnersList.find(p => p.id === 'partner_klounge');
      if (kLounge) {
        courseRoutes.push(kLounge);
      }

      const restShops = partnersList.filter(p => p.id !== 'partner_klounge');
      const matched = restShops.filter(p => {
        const catMatch = selectedActs.includes(p.category) || selectedActs.includes(p.subCategory);
        let priceVal = 0;
        if (p.priceList && p.priceList[0]) {
          const rawStr = p.priceList[0].price;
          priceVal = parseInt(rawStr.replace(/[^0-9]/g, '')) || 0;
        }
        const budgetMatch = priceVal <= budgetVal;
        return catMatch && budgetMatch;
      });

      const extraNodes = matched.slice(0, 2);
      courseRoutes = courseRoutes.concat(extraNodes);

      const titleEl = document.createElement('h4');
      titleEl.innerHTML = `<i data-lucide="compass" style="width:14px; height:14px; display:inline-block; vertical-align:middle; margin-right:4px;"></i> AI 추천 남포 상생 힐링 코스 (${courseRoutes.length}개 발견)`;
      outputArea.appendChild(titleEl);

      courseRoutes.forEach((route, idx) => {
        const isKorean = currentLang === 'kr';
        const directionLink = isKorean ? route.mapLinkNaver : route.mapLinkGoogle;
        
        const card = document.createElement('div');
        card.className = 'ai-route-timeline-card';
        
        card.innerHTML = `
          <div class="ai-card-dot"></div>
          <div class="ai-route-box">
            <h5>Step ${idx + 1}: ${route.name[currentLang] || route.name['en']}</h5>
            <p>🎁 혜택: ${route.benefits[currentLang] || route.benefits['en']}</p>
            <div style="font-size: 9px; color: var(--text-muted); margin-bottom: 6px;">
              📞 Tel: ${route.phone} | 🕒 Hours: ${route.hours}
            </div>
            <div class="ai-route-media" style="background-image: url('${route.image}')"></div>
            
            <button class="btn btn-primary btn-sm btn-nav-map" onclick="window.open('${directionLink}', '_blank')">
              <i data-lucide="navigation" style="width:10px; height:10px;"></i> 실시간 도보 길안내
            </button>
          </div>
        `;

        outputArea.appendChild(card);
      });

      initLucide();
      outputArea.scrollIntoView({ behavior: 'smooth' });
    });
  }
}

// Setup Modal Close Actions Safely
function setupModalCloseButtons() {
  document.querySelectorAll('.modal').forEach(modal => {
    const closeBtn = modal.querySelector('.modal-close');
    const backdrop = modal.querySelector('.modal-backdrop');

    const closeModal = () => {
      modal.classList.remove('active');
    };

    if (closeBtn) closeBtn.addEventListener('click', closeModal);
    if (backdrop) backdrop.addEventListener('click', closeModal);
  });
}
