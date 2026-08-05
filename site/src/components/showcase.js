import { servicesData } from '../data/services.js';

export function initShowcase() {
  const showcaseCard = document.getElementById('showcase-card');
  const trackEl = document.getElementById('showcase-carousel-track');
  const prevBtn = document.getElementById('showcase-prev');
  const nextBtn = document.getElementById('showcase-next');
  const indicatorsEl = document.getElementById('carousel-indicators');

  if (!showcaseCard || !trackEl) return;

  const iconEl = document.getElementById('showcase-icon');
  const titleEl = document.getElementById('showcase-title');
  const categoryEl = document.getElementById('showcase-category');
  const descEl = document.getElementById('showcase-description');
  const featuresEl = document.getElementById('showcase-features');
  const pickerChips = document.querySelectorAll('#service-picker .showcase-picker-chip');
  const marqueeChips = document.querySelectorAll('.marquee-chip');

  let currentServiceKey = 'sonarr';
  let currentIndex = 0;
  let totalSlides = 4;

  function updateActiveDot(index) {
    if (!indicatorsEl) return;
    const dots = indicatorsEl.querySelectorAll('.carousel-dot');
    dots.forEach((dot, i) => {
      if (i === index) {
        dot.classList.add('active');
      } else {
        dot.classList.remove('active');
      }
    });
  }

  function scrollToIndex(index, smooth = true) {
    if (totalSlides <= 1) return;
    currentIndex = (index + totalSlides) % totalSlides;
    const slideWidth = trackEl.clientWidth || trackEl.getBoundingClientRect().width;
    trackEl.scrollTo({
      left: slideWidth * currentIndex,
      behavior: smooth ? 'smooth' : 'instant'
    });
    updateActiveDot(currentIndex);
  }

  // Listen for swiping/scrolling to sync active dot indicator
  trackEl.addEventListener('scroll', () => {
    if (totalSlides <= 1) return;
    const slideWidth = trackEl.clientWidth || 1;
    const scrollLeft = trackEl.scrollLeft;
    const newIndex = Math.round(scrollLeft / slideWidth);
    if (newIndex !== currentIndex && newIndex >= 0 && newIndex < totalSlides) {
      currentIndex = newIndex;
      updateActiveDot(currentIndex);
    }
  }, { passive: true });

  function renderCarouselForService(serviceKey) {
    const data = servicesData[serviceKey];
    if (!data) return;

    const photos = data.screenshots || [];
    totalSlides = photos.length;
    currentIndex = 0;

    if (totalSlides === 0) {
      trackEl.innerHTML = `
        <div class="showcase-placeholder-card">
          <i style="font-size: 56px; margin-bottom: 1rem; color: var(--outline-variant);">hourglass_empty</i>
          <h5 style="margin: 0 0 0.5rem 0; color: var(--on-surface);">Preview Coming Soon</h5>
          <p style="margin: 0; opacity: 0.7; font-size: 0.95rem; max-width: 260px;">We are actively building out native showcases for this service. Stay tuned!</p>
        </div>
      `;
      if (prevBtn) prevBtn.style.display = 'none';
      if (nextBtn) nextBtn.style.display = 'none';
      if (indicatorsEl) indicatorsEl.innerHTML = '';
      return;
    }

    // Render slides
    trackEl.innerHTML = photos.map((url, i) => `
      <div class="carousel-slide">
        <img src="${url}" alt="${data.name} Preview ${i + 1}">
      </div>
    `).join('');

    // Reset scroll positioning
    trackEl.scrollTo({ left: 0, behavior: 'instant' });

    // Manage controls visibility
    if (totalSlides > 1) {
      if (prevBtn) prevBtn.style.display = 'flex';
      if (nextBtn) nextBtn.style.display = 'flex';
      if (indicatorsEl) {
        indicatorsEl.innerHTML = photos.map((_, i) => `
          <div class="carousel-dot${i === 0 ? ' active' : ''}" data-index="${i}"></div>
        `).join('');

        // Bind dot click events
        indicatorsEl.querySelectorAll('.carousel-dot').forEach(dot => {
          dot.addEventListener('click', (e) => {
            const targetIdx = parseInt(e.currentTarget.getAttribute('data-index'), 10);
            if (!isNaN(targetIdx)) scrollToIndex(targetIdx, true);
          });
        });
      }
    } else {
      if (prevBtn) prevBtn.style.display = 'none';
      if (nextBtn) nextBtn.style.display = 'none';
      if (indicatorsEl) indicatorsEl.innerHTML = '';
    }
  }

  function selectService(serviceKey, scroll = false) {
    const data = servicesData[serviceKey];
    if (!data || (serviceKey === currentServiceKey && !scroll)) {
      if (scroll && document.getElementById('service-showcase')) {
        document.getElementById('service-showcase').scrollIntoView({ behavior: 'smooth', block: 'start' });
      }
      return;
    }

    currentServiceKey = serviceKey;
    showcaseCard.style.opacity = '0.35';

    setTimeout(() => {
      if (iconEl) {
        iconEl.src = data.icon;
        iconEl.alt = data.name;
      }
      if (titleEl) titleEl.textContent = data.name;
      if (categoryEl) categoryEl.textContent = data.category;
      if (descEl) descEl.textContent = data.description;

      if (featuresEl) {
        featuresEl.innerHTML = data.features
          .map(feat => `<li><i>check_circle</i><span>${feat}</span></li>`)
          .join('');
      }

      renderCarouselForService(serviceKey);

      pickerChips.forEach(chip => {
        if (chip.getAttribute('data-service') === serviceKey) {
          chip.classList.add('active');
        } else {
          chip.classList.remove('active');
        }
      });

      showcaseCard.style.opacity = '1';
    }, 160);

    if (scroll && document.getElementById('service-showcase')) {
      document.getElementById('service-showcase').scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  }

  if (prevBtn) {
    prevBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      scrollToIndex(currentIndex - 1, true);
    });
  }

  if (nextBtn) {
    nextBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      scrollToIndex(currentIndex + 1, true);
    });
  }

  // Handle dot clicks for initial DOM render
  if (indicatorsEl) {
    indicatorsEl.querySelectorAll('.carousel-dot').forEach(dot => {
      dot.addEventListener('click', (e) => {
        const targetIdx = parseInt(e.currentTarget.getAttribute('data-index'), 10);
        if (!isNaN(targetIdx)) scrollToIndex(targetIdx, true);
      });
    });
  }

  pickerChips.forEach(chip => {
    chip.addEventListener('click', (e) => {
      const key = e.currentTarget.getAttribute('data-service');
      selectService(key, false);
    });
  });

  marqueeChips.forEach(chip => {
    chip.addEventListener('click', (e) => {
      const key = e.currentTarget.getAttribute('data-service');
      selectService(key, true);
    });
  });
}
