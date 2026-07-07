// app.js - Nampo GoGo Platform Advanced Logic with Tab Sync, Media Upload, Google Ratings & AI Planner

// Global Seed Load and Local Storage Initialization
let appData = null;
initLocalStorageSeed();

function initLocalStorageSeed() {
  const seed = window.NampoGoGoData;
  
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
  if (!localStorage.getItem('nampogogo_partners_v3')) {
    localStorage.setItem('nampogogo_partners_v3', JSON.stringify(seed.partners));
  }

  // Seed Notices
  if (!localStorage.getItem('nampogogo_notices')) {
    localStorage.setItem('nampogogo_notices', JSON.stringify(seed.updateHistory));
  }

  loadApplicationState();
}

let partnersList = [];
let updateHistoryList = [];

function loadApplicationState() {
  partnersList = JSON.parse(localStorage.getItem('nampogogo_partners_v3')) || [];
  updateHistoryList = JSON.parse(localStorage.getItem('nampogogo_notices')) || [];
}

// App Variables
const translations = window.NampoGoGoData.translations;
let currentLang = 'ko';
let activeTab = 'dashboard';
let currentUser = localStorage.getItem('nampogogo_user') || null;
let currentUserRole = localStorage.getItem('nampogogo_user_role') || 'visitor';
let userStamps = [];
let activeCategoryFilter = 'all';
let filterPartnerOnly = false;

// Media Upload Temporary Arrays (Holds Base64 strings)
let tempUploadedMedia = [];
let selectedThumbnailBase64 = "";

// Document Load Hook
document.addEventListener('DOMContentLoaded', () => {
  initLucide();
  loadUserStamps();
  setupLanguage();
  setupTabNavigation();
  setupUpdatePanel();
  setupAuthSystem();
  setupQuickDashboardMenu();
  renderPartnersList();
  renderTravelLog();
  setupInteractiveScans();
  setupMerchantSystem();
  setupAdminSystem();
  setupAIPlanner();
  setupCrossTabSync();

  // Hero Quick link
  document.getElementById('btn-hero-quick-link').addEventListener('click', () => {
    openPartnerDetail('partner_klounge');
  });
});

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
      if (activeTab === 'profile') {
        renderMerchantStats();
        renderAdminReviews();
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

// 3. Multi-Language System
function setupLanguage() {
  const appLangSelect = document.getElementById('app-lang-select');
  appLangSelect.addEventListener('change', (e) => {
    currentLang = e.target.value;
    updateLanguageTexts();
  });
  updateLanguageTexts();
}

function updateLanguageTexts() {
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

  renderPartnersList();
  renderTravelLog();
  updateAuthUIs();
  renderMerchantStats();
  renderAdminReviews();
}

function getTranslation(lang, key) {
  const keys = key.split('.');
  let obj = translations[lang];
  for (const k of keys) {
    if (obj && obj[k] !== undefined) {
      obj = obj[k];
    } else {
      return null;
    }
  }
  return obj;
}

// 4. Tab Navigation Router
function setupTabNavigation() {
  const navButtons = document.querySelectorAll('.nav-btn');
  const tabPanels = document.querySelectorAll('.tab-panel');

  navButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      const targetTab = btn.getAttribute('data-tab');
      
      navButtons.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');

      tabPanels.forEach(panel => {
        panel.classList.remove('active');
        if (panel.id === `tab-${targetTab}`) {
          panel.classList.add('active');
        }
      });

      activeTab = targetTab;
      
      if (targetTab === 'profile') {
        renderMerchantStats();
        renderAdminReviews();
      } else if (targetTab === 'travel-log') {
        renderTravelLog();
      }
      
      window.scrollTo({ top: 0, behavior: 'smooth' });
    });
  });
}

// 5. Quick Dashboard 7 Menu Router
function setupQuickDashboardMenu() {
  document.querySelectorAll('.menu-item-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      const menuAction = btn.getAttribute('data-menu');
      
      if (menuAction === 'log') {
        document.querySelector('[data-tab="travel-log"]').click();
      } else if (menuAction === 'benefit') {
        filterPartnerOnly = true;
        activeCategoryFilter = 'all';
        setActiveCategoryPill('all');
        document.querySelector('[data-tab="explore"]').click();
        renderPartnersList();
      } else if (menuAction === 'course') {
        // Scroll directly to AI course planner form on dashboard
        const plannerEl = document.querySelector('.ai-planner-box-layout');
        if (plannerEl) {
          plannerEl.scrollIntoView({ behavior: 'smooth' });
        }
      } else {
        filterPartnerOnly = false;
        let targetCat = 'all';
        if (menuAction === 'food') targetCat = 'food';
        if (menuAction === 'activity') targetCat = 'massage';
        if (menuAction === 'shopping') targetCat = 'shopping';
        if (menuAction === 'sightseeing') targetCat = 'sightseeing';

        activeCategoryFilter = targetCat;
        setActiveCategoryPill(targetCat);
        document.querySelector('[data-tab="explore"]').click();
        renderPartnersList();
      }
    });
  });
}

function setActiveCategoryPill(cat) {
  document.querySelectorAll('.cat-pill').forEach(pill => {
    if (pill.getAttribute('data-category') === cat) {
      pill.classList.add('active');
    } else {
      pill.classList.remove('active');
    }
  });
}

// 6. Global Notices Board Panel
function setupUpdatePanel() {
  const btnUpdateToggle = document.getElementById('btn-update-toggle');
  const updatePanel = document.getElementById('update-panel');

  renderUpdateLogs();

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

// 7. Advanced Auth & Quick Sign-up
function setupAuthSystem() {
  const authForm = document.getElementById('nampo-auth-form');
  const btnLogout = document.getElementById('btn-action-logout');
  const btnDashboardAction = document.getElementById('btn-dashboard-auth-action');

  authForm.addEventListener('submit', (e) => {
    e.preventDefault();
    const usernameInput = document.getElementById('auth-username').value.trim();
    const passwordInput = document.getElementById('auth-password').value;
    const confirmInput = document.getElementById('auth-password-confirm').value;
    const selectedRole = document.querySelector('input[name="auth-role"]:checked').value;

    if (!usernameInput) return;

    if (passwordInput !== confirmInput) {
      alert("❌ 비밀번호와 비밀번호 확인이 서로 다릅니다. 다시 입력하세요!");
      return;
    }

    // Load registered users list
    let registeredUsers = JSON.parse(localStorage.getItem('nampogogo_users')) || [];
    
    // Check if user exists
    let matchedUser = registeredUsers.find(u => u.id === usernameInput);
    if (matchedUser) {
      // Login attempt
      if (matchedUser.pw !== passwordInput) {
        alert("❌ 비밀번호가 올바르지 않습니다!");
        return;
      }
      currentUser = matchedUser.id;
      currentUserRole = matchedUser.role;
    } else {
      // Auto Sign-up
      const newUser = {
        id: usernameInput,
        pw: passwordInput,
        role: selectedRole
      };
      registeredUsers.push(newUser);
      localStorage.setItem('nampogogo_users', JSON.stringify(registeredUsers));
      
      currentUser = usernameInput;
      currentUserRole = selectedRole;
    }

    localStorage.setItem('nampogogo_user', currentUser);
    localStorage.setItem('nampogogo_user_role', currentUserRole);
    
    loadUserStamps();
    updateAuthUIs();
    authForm.reset();
    
    alert(`👋 Welcome to Nampo GoGo!\nID: ${currentUser}\nRole: ${getTranslation(currentLang, 'role' + currentUserRole.charAt(0).toUpperCase() + currentUserRole.slice(1))}`);
    
    document.querySelector('[data-tab="dashboard"]').click();
  });

  btnLogout.addEventListener('click', () => {
    currentUser = null;
    currentUserRole = 'visitor';
    userStamps = [];
    localStorage.removeItem('nampogogo_user');
    localStorage.removeItem('nampogogo_user_role');
    updateAuthUIs();
    alert("Logged out successfully.");
    document.querySelector('[data-tab="dashboard"]').click();
  });

  btnDashboardAction.addEventListener('click', () => {
    document.querySelector('[data-tab="profile"]').click();
  });

  updateAuthUIs();
}

function updateAuthUIs() {
  const dashboardHeading = document.getElementById('user-status-heading');
  const dashboardDesc = document.getElementById('user-status-desc');
  const btnDashboardAction = document.getElementById('btn-dashboard-auth-action');
  const dashboardRoleBadge = document.getElementById('dashboard-user-role');
  
  const profileUsername = document.getElementById('profile-username');
  const profileRoleBadge = document.getElementById('profile-role-badge');
  const profileAvatarEmoji = document.getElementById('profile-avatar-emoji');
  
  const authFormCard = document.getElementById('auth-form-card');
  const logoutCard = document.getElementById('logout-card');
  
  const merchantControlCard = document.getElementById('merchant-control-card');
  const adminControlCard = document.getElementById('admin-control-card');

  merchantControlCard.classList.add('hidden');
  adminControlCard.classList.add('hidden');

  if (currentUser) {
    const roleTxt = getTranslation(currentLang, 'role' + currentUserRole.charAt(0).toUpperCase() + currentUserRole.slice(1));
    
    dashboardHeading.textContent = currentUser;
    dashboardDesc.textContent = `${getTranslation(currentLang, 'welcomeUser')}`;
    dashboardRoleBadge.textContent = roleTxt;
    dashboardRoleBadge.classList.remove('hidden');
    btnDashboardAction.textContent = "My Panel";

    profileUsername.textContent = currentUser;
    profileRoleBadge.textContent = roleTxt;
    authFormCard.classList.add('hidden');
    logoutCard.classList.remove('hidden');
    
    if (currentUserRole === 'merchant') {
      merchantControlCard.classList.remove('hidden');
      profileAvatarEmoji.textContent = '🏢';
    } else if (currentUserRole === 'admin') {
      adminControlCard.classList.remove('hidden');
      profileAvatarEmoji.textContent = '👑';
    } else {
      profileAvatarEmoji.textContent = '👤';
    }
  } else {
    dashboardHeading.textContent = "Guest User";
    dashboardDesc.textContent = getTranslation(currentLang, 'pleaseLogin');
    dashboardRoleBadge.classList.add('hidden');
    btnDashboardAction.textContent = "Login";

    profileUsername.textContent = "Guest User";
    profileRoleBadge.textContent = "Visitor";
    profileAvatarEmoji.textContent = '👤';
    authFormCard.classList.remove('hidden');
    logoutCard.classList.add('hidden');
  }

  document.getElementById('dashboard-stamp-count').textContent = `${userStamps.length} / 5`;
}

// 8. Render Explore Partners (Priority order, full stars, direction links)
function renderPartnersList() {
  const container = document.getElementById('partners-cards-container');
  if (!container) return;
  container.innerHTML = '';

  let filtered = [...partnersList];
  if (activeCategoryFilter !== 'all') {
    filtered = filtered.filter(p => p.category === activeCategoryFilter);
  }

  if (filterPartnerOnly) {
    filtered = filtered.filter(p => p.isPartner === true);
  }

  // Prepend K-Lounge to top
  const kLoungeObj = partnersList.find(p => p.id === 'partner_klounge');
  if (kLoungeObj) {
    filtered = filtered.filter(p => p.id !== 'partner_klounge');
    filtered.unshift(kLoungeObj);
  }

  filtered.forEach(p => {
    const card = document.createElement('div');
    const isKLounge = p.id === 'partner_klounge';
    card.className = `partner-card ${isKLounge ? 'priority-card' : ''}`;
    
    const isKorean = currentLang === 'ko';
    const directionLink = isKorean ? p.mapLinkNaver : p.mapLinkGoogle;
    
    card.innerHTML = `
      ${isKLounge ? `<span class="priority-ribbon">⭐ K-LOUNGE PRIORITY</span>` : ''}
      <div class="partner-card-img" style="background-image: url('${p.image}')">
        <span class="partner-card-badge">${getTranslation(currentLang, 'cat' + p.category.charAt(0).toUpperCase() + p.category.slice(1))}</span>
      </div>
      <div class="partner-card-body">
        <div class="card-title-row">
          <h3>${p.name[currentLang] || p.name['en']}</h3>
          <div class="rating-badge"><i data-lucide="star"></i> ${p.rating.toFixed(1)}</div>
        </div>
        <div class="benefit-strip">
          <h5>${getTranslation(currentLang, 'benefitTitle')}</h5>
          <p>${p.benefits[currentLang] || p.benefits['en']}</p>
        </div>
        <div class="card-footer-row">
          <span>📍 ${getTranslation(currentLang, 'distance')}: <strong>${p.distanceValue}</strong></span>
          <button class="btn btn-primary btn-sm btn-nav-map" onclick="event.stopPropagation(); window.open('${directionLink}', '_blank')">
            <i data-lucide="navigation"></i> ${getTranslation(currentLang, 'getDirection')}
          </button>
        </div>
      </div>
    `;

    card.addEventListener('click', () => openPartnerDetail(p.id));
    container.appendChild(card);
  });

  initLucide();
  setupCategoryPills();
}

function setupCategoryPills() {
  document.querySelectorAll('.cat-pill').forEach(pill => {
    const newPill = pill.cloneNode(true);
    pill.parentNode.replaceChild(newPill, pill);

    newPill.addEventListener('click', () => {
      document.querySelectorAll('.cat-pill').forEach(p => p.classList.remove('active'));
      newPill.classList.add('active');
      activeCategoryFilter = newPill.getAttribute('data-category');
      filterPartnerOnly = false;
      renderPartnersList();
    });
  });
}

// 9. Partner Detail Modal (Gallery, Google-style Accordion Ratings)
function openPartnerDetail(id) {
  const p = partnersList.find(item => item.id === id);
  if (!p) return;

  const contentWrap = document.getElementById('partner-modal-body-content');
  const isStamped = userStamps.some(s => s.partnerId === p.id);
  const isKorean = currentLang === 'ko';
  const directionLink = isKorean ? p.mapLinkNaver : p.mapLinkGoogle;

  // Build Pricing rows
  let pricingRows = '';
  p.priceList.forEach(item => {
    pricingRows += `
      <tr>
        <td>${item.name[currentLang] || item.name['en']}</td>
        <td class="price-col">${item.price}</td>
      </tr>
    `;
  });

  // Build Media Gallery slides (Images & Videos)
  let mediaGallerySlides = '';
  // Prepend default main image
  mediaGallerySlides += `<div class="detail-gallery-img" style="background-image: url('${p.image}')"></div>`;
  
  if (p.gallery && p.gallery.length > 0) {
    p.gallery.forEach(file => {
      if (file.type === 'video' || file.data.startsWith('data:video/')) {
        mediaGallerySlides += `<video class="detail-gallery-video" controls src="${file.data}"></video>`;
      } else {
        mediaGallerySlides += `<div class="detail-gallery-img" style="background-image: url('${file.data}')"></div>`;
      }
    });
  }

  // Build Reviews list
  let reviewsMarkup = '';
  if (p.reviews.length === 0) {
    reviewsMarkup = `<p class="empty-state text-center">${getTranslation(currentLang, 'noReviews')}</p>`;
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

  // Review writer block
  let writerMarkup = '';
  if (currentUser) {
    if (isStamped) {
      writerMarkup = `
        <div class="review-writer-box">
          <h5 style="font-size:11px; margin-bottom:8px; font-weight:800;">✍️ Write Verified Review</h5>
          <div class="writer-rating-select">
            <span data-trans="ratingLabel">${getTranslation(currentLang, 'ratingLabel')}</span>
            <select id="review-rating-select">
              <option value="5">★ 5.0</option>
              <option value="4">★ 4.0</option>
              <option value="3">★ 3.0</option>
              <option value="2">★ 2.0</option>
              <option value="1">★ 1.0</option>
            </select>
          </div>
          <textarea id="review-comment-textarea" class="writer-textarea" rows="2" placeholder="${getTranslation(currentLang, 'reviewInputPlaceholder')}"></textarea>
          <button class="btn btn-primary btn-sm btn-block" id="btn-submit-review-act">${getTranslation(currentLang, 'reviewBtn')}</button>
        </div>
      `;
    } else {
      writerMarkup = `
        <div class="glass-box text-center" style="margin-top: 16px; border-color: var(--accent); padding: 10px;">
          <p class="review-alert-msg" data-trans="reviewAuthError">${getTranslation(currentLang, 'reviewAuthError')}</p>
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

  // Calculate Google-style metrics (Default scores or computed ones)
  const sc = p.scores || { hygiene: 4.8, taste: 4.8, service: 4.8, cleanliness: 4.8 };

  contentWrap.innerHTML = `
    <!-- Media Scroll Gallery instead of single cover -->
    <div class="modal-detail-media-scroller">
      ${mediaGallerySlides}
    </div>

    <div class="modal-detail-title-row">
      <h3>${p.name[currentLang] || p.name['en']}</h3>
      <div class="rating-badge"><i data-lucide="star"></i> ${p.rating.toFixed(1)}</div>
    </div>

    <!-- Google-style Accordion Detailed Rating 요약 -->
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
        <span class="rating-metric-label">맛</span>
        <div class="metric-bar-bg"><div class="metric-bar-fill" style="width: ${sc.taste * 20}%"></div></div>
        <span class="metric-score-val">${sc.taste.toFixed(1)}</span>
      </div>
      <div class="rating-metric-bar-row">
        <span class="rating-metric-label">서비스</span>
        <div class="metric-bar-bg"><div class="metric-bar-fill" style="width: ${sc.service * 20}%"></div></div>
        <span class="metric-score-val">${sc.service.toFixed(1)}</span>
      </div>
      <div class="rating-metric-bar-row">
        <span class="rating-metric-label">청결</span>
        <div class="metric-bar-bg"><div class="metric-bar-fill" style="width: ${sc.cleanliness * 20}%"></div></div>
        <span class="metric-score-val">${sc.cleanliness.toFixed(1)}</span>
      </div>
    </div>

    <!-- Modal Tab buttons -->
    <div class="modal-tabs-nav" style="margin-top: 14px;">
      <button class="modal-tab-btn active" data-tab-panel="modal-panel-info">Introduction</button>
      <button class="modal-tab-btn" data-tab-panel="modal-panel-pricing">Price List</button>
      <button class="modal-tab-btn" data-tab-panel="modal-panel-seo">SEO Crawler Tag</button>
    </div>

    <!-- TAB PANEL 1: Info -->
    <div class="modal-tab-panel active" id="modal-panel-info">
      <div class="benefit-strip">
        <h5 data-trans="benefitTitle">${getTranslation(currentLang, 'benefitTitle')}</h5>
        <p>${p.benefits[currentLang] || p.benefits['en']}</p>
      </div>
      
      <div class="glass-box" style="margin-bottom:12px; font-size:11px; padding:12px; line-height:1.5;">
        <div>📍 <strong>Address:</strong> ${p.address[currentLang] || p.address['en']}</div>
        <div style="margin-top:4px;">📞 <strong>Tel:</strong> ${p.phone}</div>
        <div style="margin-top:4px;">🕒 <strong>Hours:</strong> ${p.hours}</div>
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

    <!-- TAB PANEL 3: SEO Crawler Tag Visualizer -->
    <div class="modal-tab-panel" id="modal-panel-seo">
      <div class="seo-info-box">
        <div class="seo-box-header">
          <i data-lucide="bot"></i>
          <span>Search Engine Optimization (SEO) Meta Information</span>
        </div>
        <div class="seo-tag-item">
          <strong>&lt;title&gt;</strong>
          ${p.name[currentLang] || p.name['en']} | Nampo GoGo Busan Tour
        </div>
        <div class="seo-tag-item">
          <strong>&lt;meta name="description"&gt;</strong>
          ${p.seoDescription}
        </div>
        <div class="seo-tag-item">
          <strong>&lt;meta name="keywords"&gt;</strong>
          ${p.seoKeywords}
        </div>
      </div>
    </div>

    <!-- Map redirection with 도보 길찾기 -->
    <button class="btn btn-primary btn-block" style="margin-bottom:12px;" onclick="window.open('${directionLink}', '_blank')">
      <i data-lucide="navigation"></i> ${getTranslation(currentLang, 'getDirection')} (${p.distanceValue})
    </button>

    <!-- Scan stamp action button -->
    <button class="btn btn-secondary btn-block" id="btn-trigger-qr-scan">
      <i data-lucide="scan-line"></i> 
      <span>${isStamped ? getTranslation(currentLang, 'alreadyStamped') : getTranslation(currentLang, 'scanBtnText')}</span>
    </button>

    <!-- Reviews Section -->
    <div class="reviews-section">
      <h4 data-trans="reviewTitle">${getTranslation(currentLang, 'reviewTitle')}</h4>
      <div id="modal-reviews-list">
        ${reviewsMarkup}
      </div>
      ${writerMarkup}
    </div>
  `;

  const partnerDetailModal = document.getElementById('partner-detail-modal');
  partnerDetailModal.classList.add('active');
  initLucide();

  // Setup Detailed rating accordion toggle
  const accordionHeader = document.getElementById('btn-rating-accordion-toggle');
  accordionHeader.addEventListener('click', () => {
    accordionHeader.classList.toggle('open');
  });

  setupModalTabs();

  // Bind stamp trigger
  const qrBtn = document.getElementById('btn-trigger-qr-scan');
  if (isStamped) qrBtn.setAttribute('disabled', 'true');
  
  qrBtn.addEventListener('click', () => {
    if (!currentUser) {
      alert("Please login first to check-in.");
      partnerDetailModal.classList.remove('active');
      document.querySelector('[data-tab="profile"]').click();
      return;
    }
    partnerDetailModal.classList.remove('active');
    triggerQRScanner(p.id);
  });

  // Submit verified review handler
  if (currentUser && isStamped) {
    document.getElementById('btn-submit-review-act').addEventListener('click', () => {
      const rating = parseInt(document.getElementById('review-rating-select').value);
      const text = document.getElementById('review-comment-textarea').value.trim();

      if (!text) {
        alert("Please write a short review content.");
        return;
      }

      // Add to reviews list
      const reviewObj = {
        username: currentUser,
        rating: rating,
        content: {
          ko: text,
          en: text,
          zh: text,
          ja: text
        }
      };

      p.reviews.unshift(reviewObj);

      // Recalculate average rating
      const sum = p.reviews.reduce((acc, cur) => acc + cur.rating, 0);
      p.rating = sum / p.reviews.length;

      // Update partners array
      savePartnersToStorage();
      alert("Verified review posted successfully!");
      openPartnerDetail(p.id); // reload modal
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

// 10. QR Scan verification
let targetQrPartnerId = null;

function triggerQRScanner(partnerId) {
  targetQrPartnerId = partnerId;
  const p = partnersList.find(item => item.id === partnerId);
  if (!p) return;

  const now = new Date();
  const dateStr = now.toLocaleDateString();
  const timeStr = now.toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit' });

  document.getElementById('stamp-card-date').textContent = dateStr;
  document.getElementById('stamp-card-time').textContent = timeStr;
  document.getElementById('qr-reward-text').textContent = p.benefits[currentLang] || p.benefits['en'];
  
  document.getElementById('qr-success-screen').classList.add('hidden');
  const qrScannerModal = document.getElementById('qr-scanner-modal');
  qrScannerModal.classList.add('active');

  setTimeout(() => {
    document.getElementById('qr-success-screen').classList.remove('hidden');
  }, 2200);
}

function setupInteractiveScans() {
  const qrScannerModal = document.getElementById('qr-scanner-modal');
  document.getElementById('btn-claim-stamp-confirm').addEventListener('click', () => {
    if (!targetQrPartnerId) return;

    const p = partnersList.find(item => item.id === targetQrPartnerId);
    if (!p) return;

    const now = new Date();
    const dateStr = now.toLocaleDateString();
    const timeStr = now.toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit' });

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
        partnerName: p.name['ko'],
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

    qrScannerModal.classList.remove('active');
    alert(`👣 Visit Stamp Saved!\nStore: ${p.name[currentLang] || p.name['en']}\nBenefit Status: Certified ✔`);
  });
}

// 11. Travel Log & Stamps Timeline
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
    if (userStamps[i]) {
      node.classList.add('active');
      node.innerHTML = '👣';
    } else {
      node.innerHTML = `${i + 1}`;
    }
    stampGrid.appendChild(node);
  }

  logCountNum.textContent = userStamps.length;

  const oldNodes = timeline.querySelectorAll('.timeline-node');
  oldNodes.forEach(n => n.remove());

  if (userStamps.length === 0) {
    emptyMsg.classList.remove('hidden');
    actionsBar.classList.add('hidden');
    timeline.classList.remove('active');
  } else {
    emptyMsg.classList.add('hidden');
    actionsBar.classList.remove('hidden');
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
            <label data-trans="memoLabel">${getTranslation(currentLang, 'memoLabel')}</label>
            <textarea id="memo-input-${stamp.partnerId}" rows="2" placeholder="${getTranslation(currentLang, 'memoPlaceholder')}">${stamp.memo || ''}</textarea>
            <button class="btn btn-secondary btn-sm btn-block btn-save-memo" data-id="${stamp.partnerId}">
              <i data-lucide="save" style="width:10px; height:10px;"></i> 
              <span data-trans="memoSaveBtn">${getTranslation(currentLang, 'memoSaveBtn')}</span>
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
          alert(getTranslation(currentLang, 'memoSavedSuccess'));
        }
      });

      timeline.appendChild(nodeEl);
    });

    initLucide();
    document.getElementById('btn-export-log-card').onclick = openSNSCardModal;
  }
}

function openSNSCardModal() {
  const storyStampList = document.getElementById('story-stamp-list');
  const storyUserTag = document.getElementById('story-user-tag');
  const logSnsModal = document.getElementById('log-sns-modal');
  
  storyUserTag.textContent = `@${currentUser || 'Explorer'}`;
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

  logSnsModal.classList.add('active');

  // Copy Caption Share Text
  document.getElementById('btn-copy-sns-caption').onclick = () => {
    const routeText = userStamps.map((stamp, idx) => {
      const p = partnersList.find(item => item.id === stamp.partnerId);
      const memoText = stamp.memo ? ` (${stamp.memo})` : '';
      return `${idx + 1}. ${p ? p.name[currentLang] : ''}${memoText}`;
    }).join('\n➔ ');

    const instagramText = `🔥 My Nampo GoGo Travel Footprints!\n👣 Today's route:\n${routeText}\n📍 Verified stamps collected at Nampodong, Busan.\n#NampoGoGo #BusanTour #Nampodong #BusanTravel #KLounge`;
    
    navigator.clipboard.writeText(instagramText).then(() => {
      alert(getTranslation(currentLang, 'snsSuccess'));
    });
  };

  document.getElementById('btn-download-sns-card').onclick = () => {
    alert("📸 Story Card Template Image downloaded successfully (Simulation)!");
  };
}

// 12. Merchant Dashboard with Media 다중 업로드 & 썸네일 셀렉터
function setupMerchantSystem() {
  const editForm = document.getElementById('merchant-store-edit-form');
  const fileInput = document.getElementById('merchant-media-files');

  // File Change event -> Base64 reader for Merchant
  fileInput.addEventListener('change', (e) => {
    const files = e.target.files;
    const previewContainer = document.getElementById('merchant-media-previews');
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

        // Previews block
        const pBox = document.createElement('div');
        pBox.className = `preview-thumb-box ${isVideo ? 'video' : ''}`;
        pBox.style.backgroundImage = isVideo ? 'none' : `url('${base64Data}')`;
        
        // Radio selector
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

  editForm.addEventListener('submit', (e) => {
    e.preventDefault();
    const store = findMerchantStore();
    if (!store) return;

    store.benefits[currentLang] = document.getElementById('edit-benefit-input').value.trim();
    store.hours = document.getElementById('edit-hours-input').value.trim();
    store.phone = document.getElementById('edit-phone-input').value.trim();

    // If new files uploaded, save them
    if (tempUploadedMedia.length > 0) {
      store.gallery = tempUploadedMedia;
      if (selectedThumbnailBase64) {
        store.image = selectedThumbnailBase64;
      }
    }

    savePartnersToStorage();
    alert(getTranslation(currentLang, 'saveStoreSuccess'));
    
    // Broadcast trigger
    localStorage.setItem('nampogogo_partners_v3', JSON.stringify(partnersList));
    renderPartnersList();
  });
}

function findMerchantStore() {
  if (currentUserRole !== 'merchant') return null;
  // Match owner_klounge or general ID (fallback K-Lounge)
  const storeId = currentUser.toLowerCase().replace('owner_', 'partner_');
  return partnersList.find(p => p.id === storeId) || partnersList[0];
}

function renderMerchantStats() {
  if (currentUserRole !== 'merchant') return;

  const store = findMerchantStore();
  if (!store) return;

  document.getElementById('edit-benefit-input').value = store.benefits[currentLang] || store.benefits['en'];
  document.getElementById('edit-hours-input').value = store.hours;
  document.getElementById('edit-phone-input').value = store.phone;

  document.getElementById('merchant-review-count').textContent = `${store.reviews.length}개`;
  
  const tbody = document.querySelector('#merchant-visit-logs-table tbody');
  tbody.innerHTML = '';

  const visitLogs = [];
  for (let i = 0; i < localStorage.length; i++) {
    const key = localStorage.key(i);
    if (key.startsWith('nampogogo_stamps_')) {
      const visitorName = key.replace('nampogogo_stamps_', '');
      const stamps = JSON.parse(localStorage.getItem(key)) || [];
      
      stamps.forEach(s => {
        if (s.partnerId === store.id) {
          visitLogs.push({
            time: s.timestamp + ' (' + s.date + ')',
            visitor: visitorName,
            certified: 'Yes'
          });
        }
      });
    }
  }

  if (visitLogs.length === 0) {
    tbody.innerHTML = `<tr><td colspan="3" class="text-center" style="color:var(--text-muted);">No QR check-ins recorded yet.</td></tr>`;
  } else {
    visitLogs.forEach(log => {
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td>${log.time}</td>
        <td>${log.visitor}</td>
        <td class="text-success">${log.certified}</td>
      `;
      tbody.appendChild(tr);
    });
  }
}

// 13. ADMIN Console logic with File Upload & Tab Sync trigger
function setupAdminSystem() {
  const storeForm = document.getElementById('admin-add-store-form');
  const noticeForm = document.getElementById('admin-add-notice-form');
  const fileInput = document.getElementById('admin-media-files');

  // File Change event -> Base64 reader for Admin
  fileInput.addEventListener('change', (e) => {
    const files = e.target.files;
    const previewContainer = document.getElementById('admin-media-previews');
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
        radio.name = 'admin-thumb-select';
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

  storeForm.addEventListener('submit', (e) => {
    e.preventDefault();
    const nameVal = document.getElementById('admin-store-name').value.trim();
    const catVal = document.getElementById('admin-store-cat').value;
    const imgVal = document.getElementById('admin-store-img').value.trim();
    const benefitVal = document.getElementById('admin-store-benefit').value.trim();
    const priceVal = document.getElementById('admin-store-price').value.trim();
    const isPartnerChecked = document.getElementById('admin-store-ispartner').checked;

    const newId = 'partner_' + Date.now();

    // Default main image, or use selected thumbnail base64
    const finalCoverImg = selectedThumbnailBase64 || imgVal;

    const newStoreObj = {
      id: newId,
      name: { ko: nameVal, en: nameVal, zh: nameVal, ja: nameVal },
      category: catVal,
      isPartner: isPartnerChecked,
      image: finalCoverImg,
      gallery: tempUploadedMedia, // include multiple base64 uploads
      rating: 5.0,
      scores: { hygiene: 5.0, taste: 5.0, service: 5.0, cleanliness: 5.0 },
      posX: 50,
      posY: 50,
      mapLinkNaver: `https://map.naver.com/v5/directions/14363294,35.097489,내위치,,/14363310,35.098222,목적지,,/walk`,
      mapLinkGoogle: `https://www.google.com/maps/dir/?api=1&origin=35.097489,129.034789&destination=35.098222,129.035789&travelmode=walking`,
      distanceValue: "350m",
      address: { ko: "부산 중구 남포동 일대", en: "Nampodong, Jung-gu, Busan", zh: "釜山中区南浦洞", ja: "釜山中区南浦洞" },
      phone: "+82-51-111-2222",
      hours: "11:00 - 22:00",
      priceList: [
        { name: { ko: "대표 패키지 코스", en: "Signature Package", zh: "招牌主打套餐", ja: "代表コース" }, price: priceVal }
      ],
      menuForeign: {
        en: `Signature Course - ${priceVal}`,
        zh: `招牌套餐 - ${priceVal}`,
        ja: `代表メニュー - ${priceVal}`
      },
      benefits: { ko: benefitVal, en: benefitVal, zh: benefitVal, ja: benefitVal },
      seoDescription: `${nameVal} - 남포동에 위치한 제휴매장 정보.`,
      seoKeywords: `남포동 ${nameVal}, 부산 ${nameVal}`,
      reviews: []
    };

    partnersList.unshift(newStoreObj);
    savePartnersToStorage();
    alert(getTranslation(currentLang, 'addStoreSuccess'));
    
    // Broadcast trigger
    localStorage.setItem('nampogogo_partners_v3', JSON.stringify(partnersList));

    storeForm.reset();
    document.getElementById('admin-media-previews').innerHTML = '';
    tempUploadedMedia = [];
    selectedThumbnailBase64 = "";

    renderPartnersList();
    document.querySelector('[data-tab="explore"]').click();
  });

  noticeForm.addEventListener('submit', (e) => {
    e.preventDefault();
    const noticeText = document.getElementById('admin-notice-textarea').value.trim();
    if (!noticeText) return;

    const now = new Date();
    const dateStr = now.toISOString().split('T')[0];

    updateHistoryList.unshift({
      date: dateStr,
      content: noticeText
    });

    localStorage.setItem('nampogogo_notices', JSON.stringify(updateHistoryList));
    alert("Notice posted successfully!");
    
    // Broadcast trigger
    localStorage.setItem('nampogogo_notices', JSON.stringify(updateHistoryList));

    document.getElementById('admin-notice-textarea').value = '';
    renderUpdateLogs();
  });
}

function renderAdminReviews() {
  if (currentUserRole !== 'admin') return;

  const tbody = document.querySelector('#admin-reviews-table tbody');
  if (!tbody) return;
  tbody.innerHTML = '';

  let count = 0;
  partnersList.forEach(p => {
    p.reviews.forEach(rev => {
      count++;
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td>${p.id}</td>
        <td>${rev.username}</td>
        <td class="text-warning">★ ${rev.rating.toFixed(1)}</td>
        <td>${rev.content[currentLang] || rev.content['en']}</td>
      `;
      tbody.appendChild(tr);
    });
  });

  if (count === 0) {
    tbody.innerHTML = `<tr><td colspan="4" class="text-center" style="color:var(--text-muted);">No reviews written on platform yet.</td></tr>`;
  }
}

// 14. AI Course Planner Logic (with K-Lounge enforced priority first)
function setupAIPlanner() {
  const btnPlanner = document.getElementById('btn-run-ai-recommend');
  const outputArea = document.getElementById('ai-course-output-area');

  btnPlanner.addEventListener('click', () => {
    // Retrieve checks and budget selector
    const selectedActs = Array.from(document.querySelectorAll('input[name="ai-activities"]:checked')).map(el => el.value);
    const budgetVal = parseInt(document.getElementById('ai-budget-select').value);

    if (selectedActs.length === 0) {
      alert("하고 싶은 활동을 최소 1개 이상 선택해 주세요!");
      return;
    }

    outputArea.innerHTML = '';
    outputArea.classList.remove('hidden');

    // Filtering algorithm
    let courseRoutes = [];

    // Enforce 1st Spot: K-Lounge Massage & Head Spa
    const kLounge = partnersList.find(p => p.id === 'partner_klounge');
    if (kLounge) {
      courseRoutes.push(kLounge);
    }

    // Filter other matching partners based on category & price budget
    const restShops = partnersList.filter(p => p.id !== 'partner_klounge');
    const matched = restShops.filter(p => {
      // check category match
      const catMatch = selectedActs.includes(p.category);
      
      // parse price to integer for comparison
      // e.g. "40,000 KRW" -> 40000, "6,500 KRW" -> 6500
      let priceVal = 0;
      if (p.priceList && p.priceList[0]) {
        const rawStr = p.priceList[0].price;
        priceVal = parseInt(rawStr.replace(/[^0-9]/g, '')) || 0;
      }

      const budgetMatch = priceVal <= budgetVal;
      return catMatch && budgetMatch;
    });

    // Pick top 2 matched to make 3-step course (K-Lounge + 2 matched)
    const extraNodes = matched.slice(0, 2);
    courseRoutes = courseRoutes.concat(extraNodes);

    // Render Course Timeline Cards
    const titleEl = document.createElement('h4');
    titleEl.innerHTML = `<i data-lucide="compass" style="width:14px; height:14px; display:inline-block; vertical-align:middle; margin-right:4px;"></i> AI 추천 남포 상생 힐링 코스 (${courseRoutes.length}개 발견)`;
    outputArea.appendChild(titleEl);

    courseRoutes.forEach((route, idx) => {
      const isKorean = currentLang === 'ko';
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
    // Scroll smoothly to output
    outputArea.scrollIntoView({ behavior: 'smooth' });
  });
}

// Modal closing hooks
document.querySelectorAll('.modal').forEach(modal => {
  const closeBtn = modal.querySelector('.modal-close');
  const backdrop = modal.querySelector('.modal-backdrop');

  const closeModal = () => {
    modal.classList.remove('active');
  };

  if (closeBtn) closeBtn.addEventListener('click', closeModal);
  if (backdrop) backdrop.addEventListener('click', closeModal);
});
