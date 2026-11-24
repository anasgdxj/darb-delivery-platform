
(() => {
 const root=document.documentElement;
 const themeToggle=document.getElementById('themeToggle');
 const themeIcon=document.getElementById('themeIcon');
 const storedTheme=(()=>{try{return localStorage.getItem('darb-site-theme')}catch{return null}})();
 const prefersDark=window.matchMedia&&window.matchMedia('(prefers-color-scheme: dark)').matches;
 function setTheme(dark){root.classList.toggle('dark',dark);themeToggle.setAttribute('aria-pressed',String(dark));themeToggle.setAttribute('aria-label',dark?'تفعيل المظهر الفاتح':'تفعيل المظهر الداكن');themeIcon.innerHTML=dark?'<path d="M20.5 15.5A8.5 8.5 0 0 1 8.5 3.5 8.5 8.5 0 1 0 20.5 15.5Z"/>':'<circle cx="12" cy="12" r="4"/><path d="M12 2v2m0 16v2M4.93 4.93l1.42 1.42m11.3 11.3 1.42 1.42M2 12h2m16 0h2M4.93 19.07l1.42-1.42m11.3-11.3 1.42-1.42"/>';try{localStorage.setItem('darb-site-theme',dark?'dark':'light')}catch{}}
 setTheme(storedTheme?storedTheme==='dark':prefersDark);
 themeToggle.addEventListener('click',()=>setTheme(!root.classList.contains('dark')));
 const menuToggle=document.getElementById('menuToggle'),mobilePanel=document.getElementById('mobilePanel');
 menuToggle.addEventListener('click',()=>{const open=mobilePanel.classList.toggle('open');menuToggle.setAttribute('aria-expanded',String(open));menuToggle.setAttribute('aria-label',open?'إغلاق القائمة':'فتح القائمة')});
 mobilePanel.querySelectorAll('a').forEach(a=>a.addEventListener('click',()=>{mobilePanel.classList.remove('open');menuToggle.setAttribute('aria-expanded','false')}));
 const cities={
  damascus:{name:'دمشق',code:'DAMASCUS / SY',description:'نقطة انطلاق شبكة دَرْب ومساراتها.'},
  aleppo:{name:'حلب',code:'ALEPPO / SY',description:'مسارات للمتاجر والتوصيل المستقل.'},
  homs:{name:'حمص',code:'HOMS / SY',description:'ربط الطلبات المحلية بمسارات السائقين.'},
  hama:{name:'حماة',code:'HAMA / SY',description:'تجربة توصيل مرنة بحسب توفر الخدمة.'},
  latakia:{name:'اللاذقية',code:'LATAKIA / SY',description:'امتداد شبكة دَرْب نحو الساحل.'}
 };
 const cityButtons=document.querySelectorAll('[data-city]');
 cityButtons.forEach(button=>button.addEventListener('click',()=>{const city=cities[button.dataset.city];if(!city)return;cityButtons.forEach(item=>item.setAttribute('aria-pressed',String(item===button)));document.getElementById('cityName').textContent=city.name;document.getElementById('cityCode').textContent=city.code;document.getElementById('cityDescription').textContent=city.description}));
 document.getElementById('year').textContent=String(new Date().getFullYear());
})();
