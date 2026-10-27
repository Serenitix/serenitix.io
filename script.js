// ==========================================
// Serenitix Website JavaScript
// ==========================================


// ==========================================
// FAQ Accordion
// ==========================================

const faqButtons = document.querySelectorAll(".faq-question");

faqButtons.forEach((button) => {

    button.addEventListener("click", () => {

        const answer = button.nextElementSibling;

        if (answer.style.maxHeight) {

            answer.style.maxHeight = null;

        } else {

            document.querySelectorAll(".faq-answer").forEach((item) => {
                item.style.maxHeight = null;
            });

            answer.style.maxHeight = answer.scrollHeight + "px";

        }

    });

});


// ==========================================
// Scroll To Top Button
// ==========================================

const scrollButton = document.getElementById("scrollTopButton");

window.addEventListener("scroll", () => {

    if (window.scrollY > 400) {

        scrollButton.style.display = "block";

    } else {

        scrollButton.style.display = "none";

    }

});

scrollButton.addEventListener("click", () => {

    window.scrollTo({

        top: 0,
        behavior: "smooth"

    });

});


// ==========================================
// Smooth Scrolling
// ==========================================

const navigationLinks = document.querySelectorAll("nav a");

navigationLinks.forEach((link) => {

    link.addEventListener("click", (event) => {

        event.preventDefault();

        const section = document.querySelector(link.getAttribute("href"));

        if (section) {

            section.scrollIntoView({

                behavior: "smooth"

            });

        }

    });

});


// ==========================================
// Fade In Animation
// ==========================================

const fadeElements = document.querySelectorAll(
    ".service-card, .about, .stat-card, .faq-item, .contact"
);

const observer = new IntersectionObserver((entries) => {

    entries.forEach((entry) => {

        if (entry.isIntersecting) {

            entry.target.classList.add("fade-in");
            entry.target.classList.add("show");

        }

    });

}, {

    threshold: 0.2

});

fadeElements.forEach((element) => {

    element.classList.add("fade-in");

    observer.observe(element);

});


// ==========================================
// Mobile Menu
// ==========================================

const menuButton = document.getElementById("menuButton");
const navigation = document.querySelector("nav");

menuButton.addEventListener("click", () => {

    if (navigation.style.display === "flex") {

        navigation.style.display = "none";

    } else {

        navigation.style.display = "flex";
        navigation.style.flexDirection = "column";
        navigation.style.position = "absolute";
        navigation.style.top = "80px";
        navigation.style.right = "30px";
        navigation.style.background = "#08111f";
        navigation.style.padding = "20px";
        navigation.style.borderRadius = "12px";
        navigation.style.gap = "15px";
        navigation.style.boxShadow = "0 0 20px rgba(0,0,0,.4)";

    }

});


// ==========================================
// Hero Button Effects
// ==========================================

const primaryButtons = document.querySelectorAll(".primaryButton");

primaryButtons.forEach((button) => {

    button.addEventListener("mouseenter", () => {

        button.style.transform = "translateY(-3px) scale(1.03)";

    });

    button.addEventListener("mouseleave", () => {

        button.style.transform = "translateY(0) scale(1)";

    });

});


// ==========================================
// Animated Network Background
// ==========================================

const canvas = document.getElementById("backgroundCanvas");
const ctx = canvas.getContext("2d");

canvas.width = window.innerWidth;
canvas.height = window.innerHeight;

const particles = [];

class Particle {

    constructor() {

        this.x = Math.random() * canvas.width;
        this.y = Math.random() * canvas.height;

        this.size = Math.random() * 2 + 1;

        this.speedX = (Math.random() - 0.5) * 0.6;
        this.speedY = (Math.random() - 0.5) * 0.6;

    }

    update() {

        this.x += this.speedX;
        this.y += this.speedY;

        if (this.x < 0 || this.x > canvas.width) {

            this.speedX *= -1;

        }

        if (this.y < 0 || this.y > canvas.height) {

            this.speedY *= -1;

        }

    }

    draw() {

        ctx.beginPath();

        ctx.arc(this.x, this.y, this.size, 0, Math.PI * 2);

        ctx.fillStyle = "#4fd5ff";

        ctx.fill();

    }

}

for (let i = 0; i < 80; i++) {

    particles.push(new Particle());

}

function animateBackground() {

    ctx.clearRect(0, 0, canvas.width, canvas.height);

    particles.forEach((particle, index) => {

        particle.update();
        particle.draw();

        for (let j = index + 1; j < particles.length; j++) {

            const dx = particle.x - particles[j].x;
            const dy = particle.y - particles[j].y;

            const distance = Math.sqrt(dx * dx + dy * dy);

            if (distance < 120) {

                ctx.beginPath();

                ctx.moveTo(particle.x, particle.y);
                ctx.lineTo(particles[j].x, particles[j].y);

                ctx.strokeStyle = "rgba(79,213,255,0.12)";
                ctx.stroke();

            }

        }

    });

    requestAnimationFrame(animateBackground);

}

animateBackground();

window.addEventListener("resize", () => {

    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;

});