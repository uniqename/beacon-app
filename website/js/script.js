// Website JavaScript for Beacon of New Beginnings NGO

// Mobile navigation toggle
document.addEventListener('DOMContentLoaded', function() {
    const navToggle = document.getElementById('nav-toggle');
    const navMenu = document.getElementById('nav-menu');
    
    if (navToggle && navMenu) {
        navToggle.addEventListener('click', function() {
            navMenu.classList.toggle('active');
            navToggle.classList.toggle('active');
        });
    }

    // Close mobile menu when clicking on links
    const navLinks = document.querySelectorAll('.nav-link');
    navLinks.forEach(link => {
        link.addEventListener('click', () => {
            navMenu.classList.remove('active');
            navToggle.classList.remove('active');
        });
    });

    // Smooth scrolling for anchor links
    const anchorLinks = document.querySelectorAll('a[href^="#"]');
    anchorLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            const targetId = this.getAttribute('href').substring(1);
            const targetElement = document.getElementById(targetId);
            
            if (targetElement) {
                const offsetTop = targetElement.offsetTop - 100; // Account for fixed navbar
                window.scrollTo({
                    top: offsetTop,
                    behavior: 'smooth'
                });
            }
        });
    });

    // Anonymous form handling
    const anonymousForm = document.getElementById('anonymousForm');
    const contactMethodSelect = document.getElementById('contactMethod');
    const contactInfoGroup = document.getElementById('contactInfoGroup');

    if (contactMethodSelect && contactInfoGroup) {
        contactMethodSelect.addEventListener('change', function() {
            if (this.value && this.value !== '') {
                contactInfoGroup.style.display = 'block';
                document.getElementById('contactInfo').required = true;
            } else {
                contactInfoGroup.style.display = 'none';
                document.getElementById('contactInfo').required = false;
            }
        });
    }

    if (anonymousForm) {
        anonymousForm.addEventListener('submit', function(e) {
            e.preventDefault();
            
            // Show loading state
            const submitBtn = this.querySelector('button[type="submit"]');
            const originalText = submitBtn.textContent;
            submitBtn.textContent = 'Submitting...';
            submitBtn.disabled = true;

            // Simulate form submission (in production, send to backend)
            setTimeout(() => {
                alert('Your anonymous request has been submitted. Your reference ID is: ANR-' + Math.random().toString(36).substr(2, 8).toUpperCase() + '\n\nWe will follow up according to your preferences. Stay safe.');
                this.reset();
                contactInfoGroup.style.display = 'none';
                submitBtn.textContent = originalText;
                submitBtn.disabled = false;
            }, 1500);
        });
    }

    // Contact form handling
    const contactForm = document.getElementById('contactForm');
    if (contactForm) {
        contactForm.addEventListener('submit', function(e) {
            e.preventDefault();
            
            const submitBtn = this.querySelector('button[type="submit"]');
            const originalText = submitBtn.textContent;
            submitBtn.textContent = 'Sending...';
            submitBtn.disabled = true;

            // Simulate form submission
            setTimeout(() => {
                alert('Thank you for your message. We will get back to you within 24 hours.');
                this.reset();
                submitBtn.textContent = originalText;
                submitBtn.disabled = false;
            }, 1500);
        });
    }

    // Donation amount selection
    const amountButtons = document.querySelectorAll('.amount-btn');
    const customAmountInput = document.querySelector('.custom-amount');
    let selectedAmount = 0;

    amountButtons.forEach(btn => {
        btn.addEventListener('click', function() {
            // Remove active class from all buttons
            amountButtons.forEach(b => b.classList.remove('active'));
            
            // Add active class to clicked button
            this.classList.add('active');
            
            // Set selected amount
            selectedAmount = parseInt(this.dataset.amount);
            
            // Clear custom amount
            if (customAmountInput) {
                customAmountInput.value = '';
            }
        });
    });

    if (customAmountInput) {
        customAmountInput.addEventListener('input', function() {
            // Remove active class from preset buttons
            amountButtons.forEach(b => b.classList.remove('active'));
            selectedAmount = parseInt(this.value) || 0;
        });
    }

    // Payment method handling
    const paymentButtons = document.querySelectorAll('.payment-btn');
    const bankDetails = document.querySelector('.bank-details');

    paymentButtons.forEach(btn => {
        btn.addEventListener('click', function() {
            const method = this.textContent.toLowerCase();
            
            if (selectedAmount <= 0) {
                alert('Please select a donation amount first.');
                return;
            }

            if (method.includes('bank')) {
                // Show bank details
                if (bankDetails) {
                    bankDetails.style.display = 'block';
                }
                alert(`Bank transfer details are shown below. Please transfer ₵${selectedAmount} and email us the transaction reference.`);
            } else if (method.includes('mobile')) {
                // Simulate mobile money integration
                alert(`Redirecting to Mobile Money payment for ₵${selectedAmount}. You will receive a prompt on your phone.`);
            } else if (method.includes('paypal')) {
                // Simulate PayPal integration
                alert(`Redirecting to PayPal for $${(selectedAmount / 7).toFixed(2)} USD (₵${selectedAmount} GHS)`);
            }
        });
    });

    // Emergency contact quick actions
    const emergencyButtons = document.querySelectorAll('.emergency-btn');
    emergencyButtons.forEach(btn => {
        btn.addEventListener('click', function(e) {
            const href = this.getAttribute('href');
            if (href && href.startsWith('tel:')) {
                // Show confirmation for emergency calls
                const number = href.replace('tel:', '');
                const service = this.textContent.includes('191') ? 'Police' : 
                              this.textContent.includes('192') ? 'Fire Service' : 'Ambulance';
                
                if (confirm(`Call ${service} (${number})?\n\nOnly call if you are in immediate danger.`)) {
                    // Let the default behavior proceed
                    return true;
                } else {
                    e.preventDefault();
                }
            }
        });
    });

    // Scroll to top button
    const scrollBtn = document.createElement('button');
    scrollBtn.innerHTML = '↑';
    scrollBtn.className = 'scroll-to-top';
    scrollBtn.style.cssText = `
        position: fixed;
        bottom: 20px;
        right: 20px;
        background: #00796B;
        color: white;
        border: none;
        border-radius: 50%;
        width: 50px;
        height: 50px;
        font-size: 20px;
        cursor: pointer;
        display: none;
        z-index: 1000;
        box-shadow: 0 2px 10px rgba(0,0,0,0.3);
        transition: all 0.3s ease;
    `;
    
    document.body.appendChild(scrollBtn);

    // Show/hide scroll button
    window.addEventListener('scroll', function() {
        if (window.pageYOffset > 300) {
            scrollBtn.style.display = 'block';
        } else {
            scrollBtn.style.display = 'none';
        }
    });

    // Scroll to top functionality
    scrollBtn.addEventListener('click', function() {
        window.scrollTo({
            top: 0,
            behavior: 'smooth'
        });
    });

    // Quick exit functionality for safety
    let keySequence = [];
    const exitSequence = ['Escape', 'Escape', 'Escape']; // Press ESC 3 times quickly

    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
            keySequence.push(e.key);
            
            // Keep only last 3 keystrokes
            if (keySequence.length > 3) {
                keySequence = keySequence.slice(-3);
            }
            
            // Check if sequence matches
            if (keySequence.length === 3 && 
                keySequence.every((key, i) => key === exitSequence[i])) {
                
                if (confirm('Quick Exit: This will redirect you to Google for safety. Continue?')) {
                    // Clear browser history entry and redirect
                    window.location.replace('https://www.google.com');
                }
                keySequence = [];
            }
        } else {
            keySequence = [];
        }
    });

    // Add safety notice
    const safetyNotice = document.createElement('div');
    safetyNotice.innerHTML = '🛡️ Safety Tip: Press ESC key 3 times quickly for emergency exit';
    safetyNotice.style.cssText = `
        position: fixed;
        bottom: 80px;
        right: 20px;
        background: rgba(0, 121, 107, 0.9);
        color: white;
        padding: 10px 15px;
        border-radius: 25px;
        font-size: 12px;
        z-index: 1000;
        opacity: 0;
        transition: opacity 0.3s ease;
        max-width: 200px;
        text-align: center;
    `;
    
    document.body.appendChild(safetyNotice);

    // Show safety notice after page load
    setTimeout(() => {
        safetyNotice.style.opacity = '1';
        setTimeout(() => {
            safetyNotice.style.opacity = '0';
        }, 5000);
    }, 2000);
});

// Utility function to clear forms
function clearForm() {
    const form = document.getElementById('anonymousForm');
    if (form) {
        form.reset();
        document.getElementById('contactInfoGroup').style.display = 'none';
    }
}

// Service worker registration for offline support
if ('serviceWorker' in navigator) {
    window.addEventListener('load', function() {
        navigator.serviceWorker.register('/sw.js')
            .then(function(registration) {
                console.log('ServiceWorker registration successful');
            })
            .catch(function(err) {
                console.log('ServiceWorker registration failed');
            });
    });
}