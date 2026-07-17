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
let tempSignboardBase64 = "";
let tempInsideBase64List = [];
let tempVideosBase64List = [];

// Dynamic Menu Rows Temporary Data
let dynamicMenuItems = []; // Array of { id, category, name, price, imageBase64 }

// Last viewed partner store ID to backup general scan checks
let lastViewedPartnerId = "partner_jagalchi";

// Multi-Language Reference
let translations = {};

// ⚡ Debounce helper
function debounce(func, wait) {
  let timeout;
  return function(...args) {
    const context = this;
    clearTimeout(timeout);
    timeout = setTimeout(() => func.apply(context, args), wait);
  };
}

// State Persistence switches
function persistAppState() {
  localStorage.setItem('nampogogo_app_mode', appMode);
  localStorage.setItem('nampogogo_active_tab', activeTab);
}

// Direct Global Touch Handler for Mobile Compatibility
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
    // Merchant flow redirection based on approval status
    if (currentUser && currentUserRole === 'merchant') {
      const isApproved = localStorage.getItem(`nampogogo_merchant_approved_${currentUser}`) === 'true';
      if (isApproved) {
        switchTabPanel('merchant-manage');
      } else {
        switchTabPanel('merchant-auth');
      }
    } else {
      switchTabPanel('merchant-auth');
    }
  }
  persistAppState();
};

// Safe Initialization Hook
document.addEventListener('DOMContentLoaded', () => {
  console.log("🚀 Nampo GoGo App Initialization Starting...");
  
  // 🛡️ [캐시/구버전 크래시 방지 안전핀] 옛 버전의 잘못된 데이터가 스토리지에 남아있어 터지는 현상 자가 복구
  try {
    const rawPartners = localStorage.getItem('nampogogo_partners_v3');
    if (rawPartners) {
      const parsed = JSON.parse(rawPartners);
      if (!Array.isArray(parsed)) {
        // 잘못된 형태이면 강제 클리어하여 시드 유도
        localStorage.removeItem('nampogogo_partners_v3');
        console.warn("🧹 깨진 partnersList 데이터 감지 및 강제 청소 완료.");
      }
    }
  } catch (e) {
    localStorage.removeItem('nampogogo_partners_v3');
    console.warn("🧹 JSON 파싱 에러 partnersList 강제 리셋 완료.");
  }

  // Bind core DOM Elements
  partnerDetailModal = document.getElementById('partner-detail-modal');
  qrScannerModal = document.getElementById('qr-scanner-modal');
  logSnsModal = document.getElementById('log-sns-modal');

  // Load Seed and Translations Safely
  const seed = window.NampoGoGoData || { translations: {}, partners: [], updateHistory: [] };
  translations = seed.translations || {};

  // Safe isolated module executor helper
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
  runSafe('Modal Buttons Bind', () => setupModalCloseButtons());

  // Recovery of Session states on reload (State Persistence)
  runSafe('Recover Persistent App State', () => {
    const savedMode = localStorage.getItem('nampogogo_app_mode');
    const savedTab = localStorage.getItem('nampogogo_active_tab');

    if (savedMode) {
      appMode = savedMode;
      const introScreen = document.getElementById('intro-screen');
      const appWorkspace = document.getElementById('app-workspace');
      if (introScreen && appWorkspace) {
        introScreen.classList.add('hidden');
        appWorkspace.classList.remove('hidden');
      }
      renderDynamicNavigationDock();
      if (savedTab) {
        switchTabPanel(savedTab);
      } else {
        switchTabPanel(savedMode === 'tourist' ? 'tourist-explore' : 'merchant-auth');
      }
    }
  });
  
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
        renderMerchantDashboard();
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
      // Clear persistence and go home
      localStorage.removeItem('nampogogo_app_mode');
      localStorage.removeItem('nampogogo_active_tab');
      introScreen.classList.remove('hidden');
      appWorkspace.classList.add('hidden');
    });
  }

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

  if (quickModeSwitchBtn) {
    quickModeSwitchBtn.addEventListener('click', () => {
      console.log("🔄 브라우저 새로고침 실행!");
      location.reload();
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
    `;
  } else {
    // Merchant mode tabs based on approval
    const isApproved = currentUser && localStorage.getItem(`nampogogo_merchant_approved_${currentUser}`) === 'true';
    if (!isApproved) {
      navDock.innerHTML = `
        <button class="nav-btn active" data-tab="merchant-auth">
          <i data-lucide="user-check"></i>
          <span>계정 및 제휴신청</span>
        </button>
      `;
    } else {
      navDock.innerHTML = `
        <button class="nav-btn active" data-tab="merchant-manage">
          <i data-lucide="bar-chart-2"></i>
          <span>매장 관리 (대시보드)</span>
        </button>
        <button class="nav-btn" data-tab="merchant-upload">
          <i data-lucide="edit-3"></i>
          <span>매장 정보 올리기/수정</span>
        </button>
      `;
    }
  }

  const navButtons = navDock.querySelectorAll('.nav-btn');
  navButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      const targetTab = btn.getAttribute('data-tab');

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
    renderMerchantDashboard();
  } else if (panelId === 'merchant-upload') {
    renderMerchantManagementForm();
  } else if (panelId === 'merchant-auth') {
    updateMerchantAuthUI();
  }

  persistAppState();
  
  // Safe container scroll helper
  const container = document.querySelector('.nampo-body');
  if (container) {
    container.scrollTo({ top: 0, behavior: 'smooth' });
  } else {
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }
}

// 5. Multi-Language System
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
    renderMerchantDashboard();
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
  const embeddedLoginCard = document.getElementById('tourist-embedded-login-card');

  if (btnShortcut) {
    btnShortcut.addEventListener('click', () => {
      if (currentUser) {
        const profLogout = document.getElementById('tourist-profile-logout-card');
        if (profLogout) profLogout.classList.toggle('hidden');
      } else {
        if (embeddedLoginCard) embeddedLoginCard.classList.toggle('hidden');
      }
    });
  }

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
      
      if (embeddedLoginCard) embeddedLoginCard.classList.add('hidden');
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
      
      const profLogout = document.getElementById('tourist-profile-logout-card');
      if (profLogout) profLogout.classList.add('hidden');
      alert("Logged out successfully.");
      switchTabPanel('tourist-explore');
    });
  }

  const generalQrBtn = document.getElementById('btn-trigger-general-qr-scan');
  if (generalQrBtn) {
    generalQrBtn.addEventListener('click', () => {
      if (!currentUser) {
        alert("관광객 로그인을 먼저 진행해 주세요!");
        if (embeddedLoginCard) embeddedLoginCard.classList.remove('hidden');
        window.scrollTo({ top: 0, behavior: 'smooth' });
        return;
      }
      triggerQRScanner(lastViewedPartnerId);
    });
  }

  updateAuthUIs();
}

function updateAuthUIs() {
  const dashboardHeading = document.getElementById('user-status-heading');
  const dashboardDesc = document.getElementById('user-status-desc');
  const btnShortcut = document.getElementById('btn-tourist-login-shortcut');
  const dashboardRoleBadge = document.getElementById('dashboard-user-role');
  
  const touristLoggedUsername = document.getElementById('tourist-logged-in-username');
  const profileLogoutCard = document.getElementById('tourist-profile-logout-card');

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
    if (btnShortcut) btnShortcut.textContent = "My Account";

    if (touristLoggedUsername) touristLoggedUsername.textContent = currentUser;
    if (profileLogoutCard) profileLogoutCard.classList.add('hidden');
  } else {
    if (dashboardHeading) dashboardHeading.textContent = "Guest User";
    if (dashboardDesc) dashboardDesc.textContent = getTranslation(currentLang, 'pleaseLogin') || 'Please login.';
    if (dashboardRoleBadge) dashboardRoleBadge.classList.add('hidden');
    if (btnShortcut) btnShortcut.textContent = "Login";

    if (profileLogoutCard) profileLogoutCard.classList.add('hidden');
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

  lastViewedPartnerId = p.id;

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
      const menuImgStr = item.image ? `<br><img src="${item.image}" style="width:60px; height:45px; border-radius:4px; margin-top:4px; object-fit:cover;">` : '';
      const catText = item.categoryText ? `<span style="font-size:9px; background:rgba(255,255,255,0.06); padding:2px 6px; border-radius:4px; margin-right:4px; color:var(--secondary);">${item.categoryText}</span>` : '';
      pricingRows += `
        <tr>
          <td>${catText}${item.name[currentLang] || item.name['en']}${menuImgStr}</td>
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
      let revPhotosStr = '';
      if (rev.photos && Array.isArray(rev.photos) && rev.photos.length > 0) {
        revPhotosStr += `<div class="review-photos-scroller">`;
        rev.photos.forEach(ph => {
          revPhotosStr += `<img src="${ph}" class="review-mini-img">`;
        });
        revPhotosStr += `</div>`;
      }

      let replyStr = '';
      if (rev.reply) {
        replyStr = `
          <div class="owner-reply-box">
            <span class="owner-reply-title">🏢 ${getTranslation(currentLang, 'ownerReply') || 'Owner Reply'}</span>
            <p class="owner-reply-text">${rev.reply}</p>
          </div>
        `;
      }

      reviewsMarkup += `
        <div class="review-item" style="border-bottom:1px dashed var(--border-medium); padding-bottom:12px; margin-bottom:12px;">
          <div class="review-user-row">
            <span>👤 ${rev.username}</span>
            <span class="text-warning">★ ${rev.rating.toFixed(1)}</span>
          </div>
          <p>${rev.content[currentLang] || rev.content['en']}</p>
          ${revPhotosStr}
          ${replyStr}
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
          
          <div class="form-group-nampo" style="margin-top:6px;">
            <label style="font-size:9px;">리뷰 사진 첨부 (선택)</label>
            <input type="file" id="review-upload-files" multiple accept="image/*" class="nampo-input" style="padding:4px;">
            <div id="review-photo-preview-wrap" class="media-thumb-selector-grid" style="margin-top:6px;"></div>
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
      <span>📊 Google-style 세부 평점 요약</span>
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
        
        <div style="border-top:1px dashed rgba(255,255,255,0.06); margin-top:10px; padding-top:8px;">
          <span style="font-size:8px; font-weight:800; color:var(--primary); text-transform:uppercase;">🌐 Foreign Language Menu</span>
          <p style="font-size:10px; color:var(--text-body); margin-top:4px; font-style:italic;">"${(p.menuForeign && p.menuForeign[currentLang]) ? p.menuForeign[currentLang] : (p.menuForeign ? p.menuForeign['en'] : 'Supported')}"</p>
        </div>
      </div>
    </div>

    <!-- TAB PANEL 3: SEO -->
    <div class="modal-tab-panel" id="modal-panel-seo">
      <div class="seo-info-box" style="background:var(--primary-soft); padding:12px; border-radius:6px; font-size:10px;">
        <div class="seo-tag-item"><strong>&lt;title&gt;</strong> ${p.name[currentLang] || p.name['en']} | Nampo GoGo</div>
        <div class="seo-tag-item" style="margin-top:6px;"><strong>&lt;meta name="description"&gt;</strong> ${p.seoDescription}</div>
        <div class="seo-tag-item" style="margin-top:6px;"><strong>&lt;meta name="keywords"&gt;</strong> ${p.seoKeywords}</div>
      </div>
    </div>

    <button class="btn btn-secondary btn-block" id="btn-trigger-qr-scan" style="margin-top: 18px; border-radius:var(--radius-pill);">
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

  let reviewBase64Photos = [];
  const reviewFileInput = document.getElementById('review-upload-files');
  const reviewPhotoPreviewWrap = document.getElementById('review-photo-preview-wrap');
  if (reviewFileInput && reviewPhotoPreviewWrap) {
    reviewFileInput.addEventListener('change', (e) => {
      reviewPhotoPreviewWrap.innerHTML = '';
      reviewBase64Photos = [];
      const files = e.target.files;
      Array.from(files).forEach(f => {
        const reader = new FileReader();
        reader.onload = (ev) => {
          reviewBase64Photos.push(ev.target.result);
          const previewDiv = document.createElement('div');
          previewDiv.className = 'preview-thumb-box';
          previewDiv.style.backgroundImage = `url('${ev.target.result}')`;
          reviewPhotoPreviewWrap.appendChild(previewDiv);
        };
        reader.readAsDataURL(f);
      });
    });
  }

  const qrBtn = document.getElementById('btn-trigger-qr-scan');
  if (qrBtn) {
    if (isStamped) qrBtn.setAttribute('disabled', 'true');
    qrBtn.addEventListener('click', () => {
      if (!currentUser) {
        alert("Please login first to check-in.");
        if (partnerDetailModal) partnerDetailModal.classList.remove('active');
        const embeddedLoginCard = document.getElementById('tourist-embedded-login-card');
        if (embeddedLoginCard) embeddedLoginCard.classList.remove('hidden');
        window.scrollTo({ top: 0, behavior: 'smooth' });
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
        content: { kr: text, en: text, ch: text, jp: text },
        photos: reviewBase64Photos
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
  const btnShowRegister = document.getElementById('btn-show-merchant-register');
  const btnShowLogin = document.getElementById('btn-show-merchant-login');
  const btnBackWelcomeR = document.getElementById('btn-back-to-welcome-r');
  const btnBackWelcomeL = document.getElementById('btn-back-to-welcome-l');

  const welcomeAuthCard = document.getElementById('merchant-welcome-auth-card');
  const registerCard = document.getElementById('merchant-register-card');
  const loginCard = document.getElementById('merchant-login-card');

  if (btnShowRegister && registerCard && welcomeAuthCard) {
    btnShowRegister.addEventListener('click', () => {
      welcomeAuthCard.classList.add('hidden');
      registerCard.classList.remove('hidden');
    });
  }
  if (btnShowLogin && loginCard && welcomeAuthCard) {
    btnShowLogin.addEventListener('click', () => {
      welcomeAuthCard.classList.add('hidden');
      loginCard.classList.remove('hidden');
    });
  }
  if (btnBackWelcomeR && registerCard && welcomeAuthCard) {
    btnBackWelcomeR.addEventListener('click', () => {
      registerCard.classList.add('hidden');
      welcomeAuthCard.classList.remove('hidden');
    });
  }
  if (btnBackWelcomeL && loginCard && welcomeAuthCard) {
    btnBackWelcomeL.addEventListener('click', () => {
      loginCard.classList.add('hidden');
      welcomeAuthCard.classList.remove('hidden');
    });
  }

  const joinForm = document.getElementById('merchant-join-form');
  const loginFormSubmit = document.getElementById('merchant-login-form-submit');
  const applyForm = document.getElementById('merchant-apply-form');

  const hourRadios = document.querySelectorAll('input[name="hours-input-type"]');
  const hoursSameBlock = document.getElementById('hours-block-same');
  const hoursEachBlock = document.getElementById('hours-block-each');

  if (hourRadios) {
    hourRadios.forEach(radio => {
      radio.addEventListener('change', () => {
        if (radio.value === 'same') {
          hoursSameBlock.classList.remove('hidden');
          hoursEachBlock.classList.add('hidden');
        } else {
          hoursSameBlock.classList.add('hidden');
          hoursEachBlock.classList.remove('hidden');
        }
      });
    });
  }

  if (joinForm) {
    joinForm.addEventListener('submit', (e) => {
      e.preventDefault();
      const usernameInput = document.getElementById('m-register-username').value.trim();
      const passwordInput = document.getElementById('m-register-password').value;
      const confirmInput = document.getElementById('m-register-password-confirm').value;

      if (!usernameInput) return;
      if (passwordInput !== confirmInput) {
        alert("❌ 비밀번호가 서로 다릅니다!");
        return;
      }

      let registeredUsers = JSON.parse(localStorage.getItem('nampogogo_users')) || [];
      if (registeredUsers.some(u => u.id === usernameInput)) {
        alert("⚠️ 이미 존재하는 아이디입니다!");
        return;
      }

      const newUser = { id: usernameInput, pw: passwordInput, role: 'merchant' };
      registeredUsers.push(newUser);
      localStorage.setItem('nampogogo_users', JSON.stringify(registeredUsers));

      currentUser = usernameInput;
      currentUserRole = 'merchant';
      localStorage.setItem('nampogogo_user', currentUser);
      localStorage.setItem('nampogogo_user_role', currentUserRole);

      alert(`🎉 회원가입 및 로그인 완료!\n환영합니다, ${currentUser} 사장님!`);
      
      joinForm.reset();
      updateMerchantAuthUI();
      renderDynamicNavigationDock();
      switchTabPanel('merchant-auth');
    });
  }

  if (loginFormSubmit) {
    loginFormSubmit.addEventListener('submit', (e) => {
      e.preventDefault();
      const usernameInput = document.getElementById('m-login-username').value.trim();
      const passwordInput = document.getElementById('m-login-password').value;

      let registeredUsers = JSON.parse(localStorage.getItem('nampogogo_users')) || [];
      const matched = registeredUsers.find(u => u.id === usernameInput && u.role === 'merchant');

      if (!matched) {
        alert("❌ 등록되지 않은 사업자 계정입니다. 먼저 회원가입을 진행해 주세요!");
        return;
      }
      if (matched.pw !== passwordInput) {
        alert("❌ 비밀번호가 일치하지 않습니다!");
        return;
      }

      currentUser = usernameInput;
      currentUserRole = matched.role;
      localStorage.setItem('nampogogo_user', currentUser);
      localStorage.setItem('nampogogo_user_role', currentUserRole);

      alert(`👋 사장님 로그인 성공! 반갑습니다, ${currentUser} 사장님!`);
      
      loginFormSubmit.reset();
      updateMerchantAuthUI();
      renderDynamicNavigationDock();

      const isApproved = localStorage.getItem(`nampogogo_merchant_approved_${currentUser}`) === 'true';
      if (isApproved) {
        switchTabPanel('merchant-manage');
      } else {
        switchTabPanel('merchant-auth');
      }
    });
  }

  const authLogoutBtn = document.getElementById('btn-merchant-logout-auth');
  const dashLogoutBtn = document.getElementById('btn-merchant-logout-dashboard');
  const uploadLogoutBtn = document.getElementById('btn-merchant-logout-upload');

  const performMerchantLogout = () => {
    currentUser = null;
    currentUserRole = 'visitor';
    localStorage.removeItem('nampogogo_user');
    localStorage.removeItem('nampogogo_user_role');
    
    tempSignboardBase64 = "";
    tempInsideBase64List = [];
    tempVideosBase64List = [];
    dynamicMenuItems = [];

    localStorage.removeItem('nampogogo_app_mode');
    localStorage.removeItem('nampogogo_active_tab');

    alert("로그아웃 되었습니다.");
    updateMerchantAuthUI();
    renderDynamicNavigationDock();
    switchTabPanel('merchant-auth');
  };

  if (authLogoutBtn) authLogoutBtn.addEventListener('click', performMerchantLogout);
  if (dashLogoutBtn) dashLogoutBtn.addEventListener('click', performMerchantLogout);
  if (uploadLogoutBtn) uploadLogoutBtn.addEventListener('click', performMerchantLogout);

  if (applyForm) {
    applyForm.addEventListener('submit', (e) => {
      e.preventDefault();
      if (!currentUser) return;

      const addr = document.getElementById('apply-address').value.trim();
      const subcat = document.getElementById('apply-subcategory').value;
      const phoneVal = document.getElementById('apply-phone').value.trim();

      localStorage.setItem(`nampogogo_merchant_status_${currentUser}`, 'pending');
      localStorage.setItem(`nampogogo_merchant_addr_${currentUser}`, addr);
      localStorage.setItem(`nampogogo_merchant_subcat_${currentUser}`, subcat);
      localStorage.setItem(`nampogogo_merchant_phone_${currentUser}`, phoneVal);

      alert("📄 제휴 신청서가 안전하게 전송되었습니다. 관리자 심사 대기 상태로 이행합니다.");
      updateMerchantAuthUI();
    });
  }

  const simApproveBtn = document.getElementById('btn-demo-approve-instantly');
  if (simApproveBtn) {
    simApproveBtn.addEventListener('click', () => {
      if (!currentUser) return;
      
      const addr = localStorage.getItem(`nampogogo_merchant_addr_${currentUser}`) || "부산 중구 남포길 18";
      const subcat = localStorage.getItem(`nampogogo_merchant_subcat_${currentUser}`) || "food";
      const phoneVal = localStorage.getItem(`nampogogo_merchant_phone_${currentUser}`) || "+82-51-245-1111";

      localStorage.setItem(`nampogogo_merchant_status_${currentUser}`, 'approved');
      localStorage.setItem(`nampogogo_merchant_approved_${currentUser}`, 'true');

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
          reviews: [
            { username: "TouristJ", rating: 5.0, content: { kr: "여기는 정말 숨겨진 맛집입니다! 강추!", en: "Super clean and wonderful service.", ch: "这里的老板非常热情，价格也很划算！", jp: "スタッフ가丁寧で非常に良かったです。" }, reply: "" }
          ],
          payments: ["신용카드", "삼성페이"],
          parking: "유"
        };
        partnersList.unshift(storeObj);
        savePartnersToStorage();
      }

      alert("🎉 [어드민 승인 완료]\n공식 승인 처리되었습니다! 매장 관리 대시보드로 이동합니다.");
      renderDynamicNavigationDock();
      switchTabPanel('merchant-manage');
    });
  }

  setupFormUploadValidators();

  const addMenuBtn = document.getElementById('btn-merchant-add-menu-row');
  if (addMenuBtn) {
    addMenuBtn.addEventListener('click', () => {
      addNewMenuFormRow();
    });
  }

  const saveStoreBtn = document.getElementById('btn-save-merchant-form');
  if (saveStoreBtn) {
    saveStoreBtn.addEventListener('click', (e) => {
      e.preventDefault();
      saveStoreDetailsComplete();
    });
  }

  const successConfirmBtn = document.getElementById('btn-success-feedback-confirm');
  const successModal = document.getElementById('merchant-success-feedback-modal');
  if (successConfirmBtn && successModal) {
    successConfirmBtn.addEventListener('click', () => {
      successModal.classList.remove('active');
      switchTabPanel('merchant-manage');
    });
  }
}

// Dynamically generate menu input fields in DOM
function addNewMenuFormRow(initialData = null) {
  const container = document.getElementById('merchant-dynamic-menu-list');
  if (!container) return;

  const rowId = 'menu-row-' + Date.now() + '-' + Math.floor(Math.random()*1000);
  const item = {
    id: rowId,
    category: initialData ? initialData.categoryText || "" : "",
    name: initialData ? initialData.name.kr || "" : "",
    price: initialData ? initialData.price || "" : "",
    imageBase64: initialData ? initialData.image || "" : ""
  };
  dynamicMenuItems.push(item);

  const rowDiv = document.createElement('div');
  rowDiv.className = 'menu-upload-row';
  rowDiv.id = rowId;
  rowDiv.style.marginBottom = '12px';
  rowDiv.style.borderBottom = '1px dashed rgba(255,255,255,0.06)';
  rowDiv.style.paddingBottom = '12px';
  rowDiv.style.position = 'relative';

  rowDiv.innerHTML = `
    <button type="button" class="btn-remove-menu-row" style="position:absolute; top:0; right:0; background:none; border:none; color:var(--accent); font-size:11px; font-weight:800; cursor:pointer;">삭제</button>
    
    <div class="form-group-nampo" style="margin-bottom:6px;">
      <label style="font-weight:normal; font-size:9px;">메뉴 분류 / 카테고리 (예: 추천 메뉴, 기본 메뉴, 계절 메뉴)</label>
      <input type="text" class="nampo-input menu-cat-field" value="${item.category}" placeholder="예: 추천 메뉴">
    </div>
    
    <div class="input-inline-row" style="margin-bottom:6px;">
      <input type="text" class="nampo-input menu-name-field" value="${item.name}" placeholder="세부 메뉴 이름" style="flex:1;">
      <input type="text" class="nampo-input menu-price-field" value="${item.price}" placeholder="가격 (예: 15,000 KRW)" style="flex:1;">
    </div>
    
    <input type="file" class="nampo-input menu-file-field" accept="image/*" style="padding:4px;">
    <div class="menu-preview-area media-thumb-selector-grid" style="margin-top:6px;">
      ${item.imageBase64 ? `<div class="preview-thumb-box" style="background-image: url('${item.imageBase64}')"></div>` : ''}
    </div>
  `;

  const catInput = rowDiv.querySelector('.menu-cat-field');
  const nameInput = rowDiv.querySelector('.menu-name-field');
  const priceInput = rowDiv.querySelector('.menu-price-field');
  const fileInput = rowDiv.querySelector('.menu-file-field');
  const previewWrap = rowDiv.querySelector('.menu-preview-area');
  const removeBtn = rowDiv.querySelector('.btn-remove-menu-row');

  // Debounced input value capture
  const debouncedValCapture = debounce(() => {
    item.category = catInput.value.trim();
    item.name = nameInput.value.trim();
    item.price = priceInput.value.trim();
    triggerDraftAutoSave();
  }, 200);

  catInput.addEventListener('input', debouncedValCapture);
  nameInput.addEventListener('input', debouncedValCapture);
  priceInput.addEventListener('input', debouncedValCapture);

  fileInput.addEventListener('change', (e) => {
    const file = e.target.files[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (ev) => {
      item.imageBase64 = ev.target.result;
      previewWrap.innerHTML = `<div class="preview-thumb-box" style="background-image: url('${ev.target.result}')"></div>`;
      triggerDraftAutoSave();
    };
    reader.readAsDataURL(file);
  });

  removeBtn.addEventListener('click', () => {
    rowDiv.remove();
    dynamicMenuItems = dynamicMenuItems.filter(i => i.id !== rowId);
    triggerDraftAutoSave();
  });

  container.appendChild(rowDiv);
}

// Clear and render dynamically menu rows list
function renderDynamicMenuRows(priceList = []) {
  const container = document.getElementById('merchant-dynamic-menu-list');
  if (!container) return;

  container.innerHTML = '';
  dynamicMenuItems = [];

  if (priceList && priceList.length > 0) {
    priceList.forEach(item => {
      addNewMenuFormRow(item);
    });
  } else {
    // Generate default 3 empty rows
    for (let i = 0; i < 3; i++) {
      addNewMenuFormRow();
    }
  }
}

// Strictly Regulated File upload verification bindings
function setupFormUploadValidators() {
  const signboardInput = document.getElementById('merchant-file-signboard');
  const insideInput = document.getElementById('merchant-files-inside');
  const videoInput = document.getElementById('merchant-files-video');

  const signboardArea = document.getElementById('signboard-preview-area');
  const insideArea = document.getElementById('inside-preview-area');
  const videoArea = document.getElementById('video-preview-area');

  if (signboardInput && signboardArea) {
    signboardInput.addEventListener('change', (e) => {
      const file = e.target.files[0];
      if (!file) return;

      const reader = new FileReader();
      reader.onload = (ev) => {
        tempSignboardBase64 = ev.target.result;
        signboardArea.innerHTML = `<div class="preview-thumb-box" style="background-image: url('${ev.target.result}')"></div>`;
        triggerDraftAutoSave();
      };
      reader.readAsDataURL(file);
    });
  }

  if (insideInput && insideArea) {
    insideInput.addEventListener('change', (e) => {
      const files = e.target.files;
      const totalPlanned = tempInsideBase64List.length + files.length;
      
      if (totalPlanned > 10) {
        alert(`⚠️ [업로드 초과 알림]\n내부 및 기타 매장 사진은 최대 10장까지만 가능합니다.\n현재 등록된 파일 수: ${tempInsideBase64List.length}장 (추가하려던 파일 수: ${files.length}장)`);
        insideInput.value = "";
        return;
      }

      Array.from(files).forEach(file => {
        const reader = new FileReader();
        reader.onload = (ev) => {
          tempInsideBase64List.push(ev.target.result);
          const box = document.createElement('div');
          box.className = 'preview-thumb-box';
          box.style.backgroundImage = `url('${ev.target.result}')`;
          insideArea.appendChild(box);
          triggerDraftAutoSave();
        };
        reader.readAsDataURL(file);
      });
    });
  }

  if (videoInput && videoArea) {
    videoInput.addEventListener('change', (e) => {
      const files = e.target.files;
      const totalPlanned = tempVideosBase64List.length + files.length;

      if (totalPlanned > 3) {
        alert(`⚠️ [동영상 업로드 초과 알림]\n매장 홍보 동영상은 최대 3개까지만 가능합니다.\n현재 등록된 동영상 수: ${tempVideosBase64List.length}개`);
        videoInput.value = "";
        return;
      }

      Array.from(files).forEach(file => {
        const reader = new FileReader();
        reader.onload = (ev) => {
          tempVideosBase64List.push(ev.target.result);
          const box = document.createElement('div');
          box.className = 'preview-thumb-box video';
          box.innerHTML = '▶';
          videoArea.appendChild(box);
          triggerDraftAutoSave();
        };
        reader.readAsDataURL(file);
      });
    });
  }

  const profileForm = document.getElementById('merchant-detail-profile-form');
  if (profileForm) {
    profileForm.querySelectorAll('input, select, textarea').forEach(el => {
      el.addEventListener('input', debouncedAutoSave);
      el.addEventListener('change', debouncedAutoSave);
    });
  }
}

// Debounced Auto Save wrapper to prevent text lag
const debouncedAutoSave = debounce(() => {
  triggerDraftAutoSave();
}, 250);

// Auto Save draft system (Active for 24 hours - ONLY saves text metadata to prevent stringify lag!)
function triggerDraftAutoSave() {
  if (!currentUser || currentUserRole !== 'merchant') return;

  const hoursType = document.querySelector('input[name="hours-input-type"]:checked')?.value || 'same';
  let hoursVal = "";
  if (hoursType === 'same') {
    hoursVal = document.getElementById('hours-input-same-val')?.value || "";
  } else {
    const days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    hoursVal = days.map(d => document.getElementById(`h-${d}`)?.value || "").join('|');
  }

  const menuMeta = dynamicMenuItems.map(i => {
    return { id: i.id, category: i.category, name: i.name, price: i.price };
  });

  const draftObj = {
    category: document.querySelector('input[name="m-upload-category"]:checked')?.value || 'food',
    benefit: document.getElementById('m-upload-benefit')?.value || "",
    phone: document.getElementById('m-upload-phone')?.value || "",
    wechat: document.getElementById('messenger-wechat')?.value || "",
    whatsapp: document.getElementById('messenger-whatsapp')?.value || "",
    line: document.getElementById('messenger-line')?.value || "",
    kakao: document.getElementById('messenger-kakao')?.value || "",
    hoursType: hoursType,
    hoursVal: hoursVal,
    menuItems: menuMeta,
    parking: document.querySelector('input[name="m-upload-parking"]:checked')?.value || '유',
    payments: Array.from(document.querySelectorAll('input[name="m-upload-payment"]:checked')).map(el => el.value),
    languages: Array.from(document.querySelectorAll('input[name="m-upload-languages"]:checked')).map(el => el.value)
  };

  const wrap = {
    data: draftObj,
    timestamp: Date.now()
  };

  localStorage.setItem(`nampogogo_draft_store_${currentUser}`, JSON.stringify(wrap));
}

// Recover draft on form render
function loadDraftRecovery() {
  const alertBox = document.getElementById('draft-recovery-alert-box');
  const raw = localStorage.getItem(`nampogogo_draft_store_${currentUser}`);
  if (!raw) {
    if (alertBox) alertBox.style.display = 'none';
    return;
  }

  const wrap = JSON.parse(raw);
  const now = Date.now();
  if (now - wrap.timestamp > 24 * 60 * 60 * 1000) {
    localStorage.removeItem(`nampogogo_draft_store_${currentUser}`);
    if (alertBox) alertBox.style.display = 'none';
    return;
  }

  const draft = wrap.data;
  if (!draft) return;

  const benefitInput = document.getElementById('m-upload-benefit');
  const phoneInput = document.getElementById('m-upload-phone');
  const wechatInput = document.getElementById('messenger-wechat');
  const whatsappInput = document.getElementById('messenger-whatsapp');
  const lineInput = document.getElementById('messenger-line');
  const kakaoInput = document.getElementById('messenger-kakao');

  if (benefitInput) benefitInput.value = draft.benefit || "";
  if (phoneInput) phoneInput.value = draft.phone || "";
  if (wechatInput) wechatInput.value = draft.wechat || "";
  if (whatsappInput) whatsappInput.value = draft.whatsapp || "";
  if (lineInput) lineInput.value = draft.line || "";
  if (kakaoInput) kakaoInput.value = draft.kakao || "";

  document.querySelectorAll('input[name="m-upload-category"]').forEach(r => {
    r.checked = r.value === draft.category;
  });
  document.querySelectorAll('input[name="m-upload-parking"]').forEach(r => {
    r.checked = r.value === draft.parking;
  });

  document.querySelectorAll('input[name="hours-input-type"]').forEach(r => {
    r.checked = r.value === draft.hoursType;
  });
  const hoursSameBlock = document.getElementById('hours-block-same');
  const hoursEachBlock = document.getElementById('hours-block-each');

  if (draft.hoursType === 'same') {
    if (hoursSameBlock) hoursSameBlock.classList.remove('hidden');
    if (hoursEachBlock) hoursEachBlock.classList.add('hidden');
    const sameInp = document.getElementById('hours-input-same-val');
    if (sameInp) sameInp.value = draft.hoursVal || "11:00 - 22:00";
  } else {
    if (hoursSameBlock) hoursSameBlock.classList.add('hidden');
    if (hoursEachBlock) hoursEachBlock.classList.remove('hidden');
    const splitVals = (draft.hoursVal || "").split('|');
    const days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    days.forEach((day, idx) => {
      const field = document.getElementById(`h-${day}`);
      if (field) field.value = splitVals[idx] || "11:00 - 22:00";
    });
  }

  const container = document.getElementById('merchant-dynamic-menu-list');
  if (container && draft.menuItems && draft.menuItems.length > 0) {
    container.innerHTML = '';
    dynamicMenuItems = [];
    draft.menuItems.forEach(item => {
      const initialSeed = {
        categoryText: item.category,
        name: { kr: item.name },
        price: item.price,
        image: ""
      };
      addNewMenuFormRow(initialSeed);
    });
  }

  document.querySelectorAll('input[name="m-upload-payment"]').forEach(box => {
    box.checked = (draft.payments || []).includes(box.value);
  });
  document.querySelectorAll('input[name="m-upload-languages"]').forEach(box => {
    box.checked = (draft.languages || []).includes(box.value);
  });

  if (alertBox) {
    alertBox.style.display = 'block';
    setTimeout(() => {
      alertBox.style.display = 'none';
    }, 3000);
  }
}

// Final Save Store Details Submission (100% try-catch crash protection & automatic Create-if-not-exist)
function saveStoreDetailsComplete() {
  const errorReportPanel = document.getElementById('upload-error-report');
  
  if (errorReportPanel) {
    errorReportPanel.innerHTML = '';
    errorReportPanel.classList.add('hidden');
  }

  try {
    let store = findMerchantStore();
    
    // Create new store object if it doesn't exist for the merchant (Zero crash guarantee)
    if (!store && currentUser) {
      const storeId = currentUser.toLowerCase().replace('owner_', 'partner_');
      store = {
        id: storeId,
        name: { kr: `${currentUser} 매장`, en: `${currentUser} Store`, ch: `${currentUser} 铺`, jp: `${currentUser} 店` },
        category: "food",
        subCategory: "food",
        isPartner: true,
        image: "",
        gallery: [],
        rating: 5.0,
        scores: { hygiene: 5.0, taste: 5.0, service: 5.0, cleanliness: 5.0 },
        posX: 129.034789,
        posY: 35.097489,
        mapLinkNaver: "https://map.naver.com",
        mapLinkGoogle: "https://maps.google.com",
        distanceValue: "150m",
        address: { kr: "부산 중구 남포동 제휴 매장" },
        phone: "",
        hours: "11:00 - 22:00",
        priceList: [],
        menuForeign: { kr: "외국어 메뉴판 구비" },
        benefits: { kr: "제휴 할인 제공" },
        seoDescription: `${currentUser} 제휴 매장`,
        seoKeywords: `남포동 ${currentUser}`,
        reviews: [],
        payments: ["신용카드"],
        parking: "유"
      };
      partnersList.unshift(store);
      savePartnersToStorage();
    }

    if (!store) {
      alert("⚠️ 오류: 제휴 사업자 세션이 불안정합니다. 로그인을 다시 진행해 주세요.");
      return;
    }

    let failedReasons = [];

    // 1. Signboard media validation
    if (!tempSignboardBase64) {
      failedReasons.push("대표(간판/대문) 사진 1장 등록이 누락되었습니다. (1장 필수)");
    }
    
    // 2. Inside photos validation
    if (tempInsideBase64List.length < 2) {
      failedReasons.push(`매장 내부 전경 사진이 부족합니다. 최소 2장 이상이 필요합니다. (현재: ${tempInsideBase64List.length}장)`);
    }

    // 3. Messenger validation
    const wechat = document.getElementById('messenger-wechat')?.value.trim() || "";
    const whatsapp = document.getElementById('messenger-whatsapp')?.value.trim() || "";
    const line = document.getElementById('messenger-line')?.value.trim() || "";
    const kakao = document.getElementById('messenger-kakao')?.value.trim() || "";

    if (!wechat && !whatsapp && !line && !kakao) {
      failedReasons.push("개인 메신저 연락망(위챗, 왓츠앱, 라인, 카톡) 중 최소 1개 이상을 필히 기입하셔야 합니다.");
    }

    // Show detailed fail reports if any checks fail
    if (failedReasons.length > 0) {
      if (errorReportPanel) {
        errorReportPanel.innerHTML = `
          <h5>⚠️ [매장 정보 등록 실패] 가이드라인 미준수 항목</h5>
          <ul>
            ${failedReasons.map(r => `<li>${r}</li>`).join('')}
          </ul>
          <p style="font-size:9px; color:var(--text-body); margin-top:8px;">기존에 통과하여 업로드해 둔 사진들은 지워지지 않고 보존되었습니다. 누락된 항목만 다시 작성 및 추가 첨부해 주세요.</p>
        `;
        errorReportPanel.classList.remove('hidden');
      }
      alert("⚠️ 가이드라인 미준수로 업로드가 실패되었습니다. 아래 미준수 리포트를 확인하고 수정해 주세요.");
      window.scrollTo({ top: 0, behavior: 'smooth' });
      return;
    }

    // Hours parsing with safe null-guards
    const hoursTypeVal = document.querySelector('input[name="hours-input-type"]:checked')?.value || "same";
    let finalHours = "";
    if (hoursTypeVal === 'same') {
      finalHours = document.getElementById('hours-input-same-val')?.value.trim() || "11:00 - 22:00";
    } else {
      const mon = document.getElementById('h-mon')?.value.trim() || "11:00 - 22:00";
      const tue = document.getElementById('h-tue')?.value.trim() || "11:00 - 22:00";
      const wed = document.getElementById('h-wed')?.value.trim() || "11:00 - 22:00";
      const thu = document.getElementById('h-thu')?.value.trim() || "11:00 - 22:00";
      const fri = document.getElementById('h-fri')?.value.trim() || "11:00 - 22:00";
      const sat = document.getElementById('h-sat')?.value.trim() || "11:00 - 23:00";
      const sun = document.getElementById('h-sun')?.value.trim() || "11:00 - 22:00";
      finalHours = `월: ${mon}, 화: ${tue}, 수: ${wed}, 목: ${thu}, 금: ${fri}, 토: ${sat}, 일: ${sun}`;
    }

    // Apply inputs to store object with safe checked reading
    const categoryVal = document.querySelector('input[name="m-upload-category"]:checked')?.value || "food";
    store.subCategory = categoryVal;
    store.category = (categoryVal === 'massage' || categoryVal === 'cafe') ? categoryVal : 'food';

    store.benefits[currentLang] = document.getElementById('m-upload-benefit')?.value.trim() || "제휴 혜택 제공";
    store.phone = document.getElementById('m-upload-phone')?.value.trim() || "";
    store.hours = finalHours;

    // Personal messengers lists
    store.messenger = { wechat, whatsapp, line, kakao };

    // Menu items list mapping from Dynamic rows
    store.priceList = [];
    dynamicMenuItems.forEach(item => {
      if (item.name && item.price) {
        store.priceList.push({
          name: { kr: item.name, en: item.name, ch: item.name, jp: item.name },
          price: item.price,
          image: item.imageBase64 || "",
          categoryText: item.category || ""
        });
      }
    });

    store.parking = document.querySelector('input[name="m-upload-parking"]:checked')?.value || "유";
    store.payments = Array.from(document.querySelectorAll('input[name="m-upload-payment"]:checked')).map(el => el.value);
    store.languages = Array.from(document.querySelectorAll('input[name="m-upload-languages"]:checked')).map(el => el.value);

    // Signboard as cover image
    store.image = tempSignboardBase64;

    // Inside files & Videos mapped to gallery array
    store.gallery = [];
    tempInsideBase64List.forEach(data => {
      store.gallery.push({ type: 'image', data: data });
    });
    tempVideosBase64List.forEach(data => {
      store.gallery.push({ type: 'video', data: data });
    });

    // Save changes to storage
    savePartnersToStorage();

    // Clear draft
    localStorage.removeItem(`nampogogo_draft_store_${currentUser}`);

    // INSTANT DEPLOYMENT: Instantly update in-memory cache and re-render tourist view
    renderPartnersList();

    // Success Feedback modal reveal instead of generic alert
    const successModal = document.getElementById('merchant-success-feedback-modal');
    if (successModal) {
      successModal.classList.add('active');
    } else {
      alert("🎉 매장 상세 메뉴 및 미디어가 성공적으로 게시되었습니다!");
      switchTabPanel('merchant-manage');
    }
  } catch (err) {
    console.error("🚨 런타임 오류가 발생했습니다:", err);
    alert(`❌ 매장 정보 등록 중 오류가 발생했습니다:\n[에러내용] ${err.message}\n관리자에게 문의바랍니다.`);
  }
}

// Render dynamic elements for merchant dashboard tab
function renderMerchantDashboard() {
  const store = findMerchantStore();
  if (!store) return;

  const dashboardUsername = document.getElementById('merchant-dashboard-username');
  if (dashboardUsername) dashboardUsername.textContent = currentUser;

  // Stats calculate
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

  drawMonthlyTrendChart(stampCount);
  renderMerchantReviewsManager(store);
}

// Toss Style dynamic SVG line chart drawer
function drawMonthlyTrendChart(stampCount) {
  const svg = document.getElementById('merchant-monthly-chart-svg');
  if (!svg) return;

  const months = ["2월", "3월", "4월", "5월", "6월", "7월"];
  const visitorsData = [45, 62, 85, 92, 110, 120 + stampCount];
  const stampsData = [8, 12, 18, 22, 28, stampCount];

  const maxVal = 160;

  svg.innerHTML = '';

  for (let i = 0; i <= 4; i++) {
    const y = 20 + i * 30;
    const gridVal = Math.round(maxVal - (i * maxVal / 4));
    svg.innerHTML += `
      <line x1="40" y1="${y}" x2="380" y2="${y}" class="chart-grid-line"></line>
      <text x="12" y="${y + 3}" class="chart-label-text">${gridVal}</text>
    `;
  }

  months.forEach((m, idx) => {
    const x = 50 + idx * 60;
    svg.innerHTML += `
      <text x="${x - 10}" y="160" class="chart-label-text" style="font-weight: 800;">${m}</text>
      <line x1="${x}" y1="140" x2="${x}" y2="145" class="chart-axis"></line>
    `;
  });

  const getCoords = (data) => {
    return data.map((val, idx) => {
      const x = 50 + idx * 60;
      const y = 140 - (val * 120 / maxVal);
      return { x, y, val };
    });
  };

  const vCoords = getCoords(visitorsData);
  const sCoords = getCoords(stampsData);

  let vPathD = `M ${vCoords[0].x} ${vCoords[0].y}`;
  for (let i = 1; i < vCoords.length; i++) {
    vPathD += ` L ${vCoords[i].x} ${vCoords[i].y}`;
  }
  svg.innerHTML += `<path d="${vPathD}" class="chart-line-visitor"></path>`;

  let sPathD = `M ${sCoords[0].x} ${sCoords[0].y}`;
  for (let i = 1; i < sCoords.length; i++) {
    sPathD += ` L ${sCoords[i].x} ${sCoords[i].y}`;
  }
  svg.innerHTML += `<path d="${sPathD}" class="chart-line-stamps"></path>`;

  vCoords.forEach(pt => {
    svg.innerHTML += `<circle cx="${pt.x}" cy="${pt.y}" class="chart-point-visitor" title="방문객: ${pt.val}명"></circle>`;
  });
  sCoords.forEach(pt => {
    svg.innerHTML += `<circle cx="${pt.x}" cy="${pt.y}" class="chart-point-stamps" title="QR스탬프: ${pt.val}건"></circle>`;
  });
}

// Render review manager items with reply submission
function renderMerchantReviewsManager(store) {
  const listContainer = document.getElementById('merchant-reviews-manager-list');
  const countBadge = document.getElementById('dashboard-review-count-badge');
  const notifBanner = document.getElementById('merchant-notification-banner');
  const notifCount = document.getElementById('notif-review-count');

  if (!listContainer) return;
  listContainer.innerHTML = '';

  const reviews = store.reviews || [];
  if (countBadge) countBadge.textContent = `${reviews.length}건`;

  if (reviews.length === 0) {
    listContainer.innerHTML = `<p class="empty-state text-center" style="font-size:11px; padding:20px; color:var(--text-body);">아직 등록된 고객 리뷰가 없습니다.</p>`;
    if (notifBanner) notifBanner.classList.add('hidden');
    return;
  }

  let unansweredCount = 0;

  reviews.forEach((rev, idx) => {
    if (!rev.reply) unansweredCount++;

    let revPhotosMarkup = '';
    if (rev.photos && Array.isArray(rev.photos) && rev.photos.length > 0) {
      revPhotosMarkup += `<div class="review-photos-scroller">`;
      rev.photos.forEach(ph => {
        revPhotosMarkup += `<img src="${ph}" class="review-mini-img">`;
      });
      revPhotosMarkup += `</div>`;
    }

    let replyMarkup = '';
    if (rev.reply) {
      replyMarkup = `
        <div class="owner-reply-box">
          <span class="owner-reply-title">🏢 사장님 답글</span>
          <p class="owner-reply-text">${rev.reply}</p>
        </div>
      `;
    } else {
      replyMarkup = `
        <div class="reply-input-row" id="reply-input-row-${idx}">
          <textarea id="reply-textarea-${idx}" rows="2" placeholder="고객 감사 답글을 입력하세요..."></textarea>
          <button class="btn btn-primary btn-sm btn-save-reply" data-idx="${idx}">답글 등록하기 ➔</button>
        </div>
      `;
    }

    const item = document.createElement('div');
    item.className = 'dashboard-review-card';
    item.innerHTML = `
      <div class="dashboard-review-header">
        <span>👤 <strong>${rev.username}</strong> 고객님</span>
        <span class="text-warning">★ ${rev.rating.toFixed(1)}</span>
      </div>
      <p style="font-size:11px; color:#f1f5f9; line-height:1.4;">${rev.content[currentLang] || rev.content['en']}</p>
      ${revPhotosMarkup}
      ${replyMarkup}
    `;

    listContainer.appendChild(item);
  });

  if (unansweredCount > 0) {
    if (notifBanner && notifCount) {
      notifCount.textContent = unansweredCount;
      notifBanner.classList.remove('hidden');
    }
  } else {
    if (notifBanner) notifBanner.classList.add('hidden');
  }

  document.querySelectorAll('.btn-save-reply').forEach(btn => {
    btn.addEventListener('click', (e) => {
      const index = parseInt(e.currentTarget.getAttribute('data-idx'));
      const txt = document.getElementById(`reply-textarea-${index}`).value.trim();

      if (!txt) {
        alert("답글 내용을 입력해 주세요!");
        return;
      }

      reviews[index].reply = txt;
      savePartnersToStorage();
      alert("💾 사장님 답글이 등록 및 동기화 완료되었습니다!");
      renderMerchantDashboard();
    });
  });
}

function updateMerchantAuthUI() {
  const welcomeAuthCard = document.getElementById('merchant-welcome-auth-card');
  const registerCard = document.getElementById('merchant-register-card');
  const loginCard = document.getElementById('merchant-login-card');
  const applyCard = document.getElementById('merchant-apply-card');
  const pendingCard = document.getElementById('merchant-pending-status-card');

  const miniProfileBar = document.getElementById('merchant-mini-profile-header');
  const miniUsername = document.getElementById('merchant-mini-username');

  if (welcomeAuthCard) welcomeAuthCard.classList.add('hidden');
  if (registerCard) registerCard.classList.add('hidden');
  if (loginCard) loginCard.classList.add('hidden');
  if (applyCard) applyCard.classList.add('hidden');
  if (pendingCard) pendingCard.classList.add('hidden');
  if (miniProfileBar) miniProfileBar.classList.add('hidden');

  if (!currentUser || currentUserRole !== 'merchant') {
    if (welcomeAuthCard) welcomeAuthCard.classList.remove('hidden');
  } else {
    if (miniProfileBar && miniUsername) {
      miniUsername.textContent = currentUser;
      miniProfileBar.classList.remove('hidden');
    }

    const isApproved = localStorage.getItem(`nampogogo_merchant_approved_${currentUser}`) === 'true';
    if (isApproved) {
      // Approved
    } else {
      const status = localStorage.getItem(`nampogogo_merchant_status_${currentUser}`);
      if (status === 'pending') {
        if (pendingCard) pendingCard.classList.remove('hidden');
      } else {
        if (applyCard) applyCard.classList.remove('hidden');
      }
    }
  }
}

function findMerchantStore() {
  if (!currentUser || currentUserRole !== 'merchant') return null;
  const storeId = currentUser.toLowerCase().replace('owner_', 'partner_');
  return partnersList.find(p => p.id === storeId) || null;
}

// 🛡️ 100% Data Preservation on Load (Form Editing Recovery)
function renderMerchantManagementForm() {
  const store = findMerchantStore();
  
  const uploadUsername = document.getElementById('merchant-upload-username');
  if (uploadUsername) uploadUsername.textContent = currentUser || "Guest";

  if (!store) {
    renderDynamicMenuRows([]);
    loadDraftRecovery();
    return;
  }

  const benefitInput = document.getElementById('m-upload-benefit');
  const phoneInput = document.getElementById('m-upload-phone');
  const wechatInput = document.getElementById('messenger-wechat');
  const whatsappInput = document.getElementById('messenger-whatsapp');
  const lineInput = document.getElementById('messenger-line');
  const kakaoInput = document.getElementById('messenger-kakao');

  if (benefitInput) benefitInput.value = store.benefits[currentLang] || store.benefits['en'] || "";
  if (phoneInput) phoneInput.value = store.phone || "";
  
  if (store.messenger) {
    if (wechatInput) wechatInput.value = store.messenger.wechat || "";
    if (whatsappInput) whatsappInput.value = store.messenger.whatsapp || "";
    if (lineInput) lineInput.value = store.messenger.line || "";
    if (kakaoInput) kakaoInput.value = store.messenger.kakao || "";
  }

  document.querySelectorAll('input[name="m-upload-category"]').forEach(r => {
    r.checked = r.value === store.subCategory;
  });
  document.querySelectorAll('input[name="m-upload-parking"]').forEach(r => {
    r.checked = r.value === store.parking;
  });

  const hoursStr = store.hours || "11:00 - 22:00";
  const hoursSameBlock = document.getElementById('hours-block-same');
  const hoursEachBlock = document.getElementById('hours-block-each');

  if (hoursStr.includes('월:')) {
    document.querySelectorAll('input[name="hours-input-type"]').forEach(r => {
      r.checked = r.value === 'each';
    });
    if (hoursSameBlock) hoursSameBlock.classList.add('hidden');
    if (hoursEachBlock) hoursEachBlock.classList.remove('hidden');

    const splitDayList = hoursStr.split(', ');
    const days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    days.forEach((day, idx) => {
      const field = document.getElementById(`h-${day}`);
      if (field && splitDayList[idx]) {
        field.value = splitDayList[idx].split(': ')[1] || "11:00 - 22:00";
      }
    });
  } else {
    document.querySelectorAll('input[name="hours-input-type"]').forEach(r => {
      r.checked = r.value === 'same';
    });
    if (hoursSameBlock) hoursSameBlock.classList.remove('hidden');
    if (hoursEachBlock) hoursEachBlock.classList.add('hidden');
    const sameInp = document.getElementById('hours-input-same-val');
    if (sameInp) sameInp.value = hoursStr;
  }

  document.querySelectorAll('input[name="m-upload-payment"]').forEach(box => {
    box.checked = (store.payments || []).includes(box.value);
  });
  document.querySelectorAll('input[name="m-upload-languages"]').forEach(box => {
    box.checked = (store.languages || []).includes(box.value);
  });

  tempSignboardBase64 = store.image || "";
  tempInsideBase64List = [];
  tempVideosBase64List = [];

  if (store.gallery && Array.isArray(store.gallery)) {
    store.gallery.forEach(file => {
      if (file.type === 'video' || file.data.startsWith('data:video/')) {
        tempVideosBase64List.push(file.data);
      } else {
        tempInsideBase64List.push(file.data);
      }
    });
  }

  const signboardArea = document.getElementById('signboard-preview-area');
  const insideArea = document.getElementById('inside-preview-area');
  const videoArea = document.getElementById('video-preview-area');

  if (signboardArea) {
    signboardArea.innerHTML = tempSignboardBase64 ? `<div class="preview-thumb-box" style="background-image: url('${tempSignboardBase64}')"></div>` : '';
  }
  if (insideArea) {
    insideArea.innerHTML = '';
    tempInsideBase64List.forEach(data => {
      const box = document.createElement('div');
      box.className = 'preview-thumb-box';
      box.style.backgroundImage = `url('${data}')`;
      insideArea.appendChild(box);
    });
  }
  if (videoArea) {
    videoArea.innerHTML = '';
    tempVideosBase64List.forEach(() => {
      const box = document.createElement('div');
      box.className = 'preview-thumb-box video';
      box.innerHTML = '▶';
      videoArea.appendChild(box);
    });
  }

  renderDynamicMenuRows(store.priceList);
  loadDraftRecovery();
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
