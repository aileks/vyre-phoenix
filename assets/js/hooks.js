let Hooks = {};

Hooks.ClearAndFocus = {
  mounted() {
    this.handleEvent("clear_input", () => {
      const input = this.el.querySelector("#message-input");
      if (input) {
        input.value = "";
        input.focus();
      } else {
        console.error("Input with ID 'message-input' not found.");
      }
    });
  },
};

Hooks.AutoScroll = {
  mounted() {
    this.autoscrollIfNeeded();
  },
  updated() {
    this.autoscrollIfNeeded();
  },
  autoscrollIfNeeded() {
    const container = this.el;
    const threshold = 100; // pixels from bottom to trigger autoscroll
    const scrollTop = container.scrollTop;
    const scrollHeight = container.scrollHeight;
    const clientHeight = container.clientHeight;

    // Calculate how far the user is from the bottom
    const distanceFromBottom = scrollHeight - (scrollTop + clientHeight);

    // On initial mount the user likely hasn't scrolled, so always scroll to the bottom.
    // On updates, only scroll if they're close enough.
    if (distanceFromBottom <= threshold || scrollTop === 0) {
      container.scrollTop = scrollHeight;
    }
  },
};

export default Hooks;
