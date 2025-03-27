const AnimatedModal = {
  mounted() {
    this.handleShow = (e) => {
      console.log("Show modal event", e);
      const modalContent = this.el.querySelector(".phx-modal-content");
      const modalOverlay = this.el.querySelector(".phx-modal-overlay");

      if (modalContent && modalOverlay) {
        modalContent.classList.add("animate-scale-in");
        modalOverlay.classList.add("animate-fade-in");
      }
    };

    this.handleClose = (e) => {
      console.log("Close modal event", e);
      if (e.detail?.disabled) return;

      // Prevent immediate close
      e.preventDefault();

      const modalContent = this.el.querySelector(".phx-modal-content");
      const modalOverlay = this.el.querySelector(".phx-modal-overlay");

      if (modalContent && modalOverlay) {
        modalContent.classList.remove("animate-scale-in");
        modalContent.classList.add("modal-content-exit");

        modalOverlay.classList.remove("animate-fade-in");
        modalOverlay.classList.add("modal-exit");

        // Wait for animation to complete before closing
        setTimeout(() => {
          this.pushEvent("close");
        }, 200);
      } else {
        this.pushEvent("close");
      }
    };

    window.addEventListener("phx:show-modal", this.handleShow);
    window.addEventListener("phx:hide-modal", this.handleClose);
  },

  destroyed() {
    window.removeEventListener("phx:show-modal", this.handleShow);
    window.removeEventListener("phx:hide-modal", this.handleClose);
  },
};
