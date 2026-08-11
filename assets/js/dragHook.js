import Sortable from '../vendor/Sortable';
import {sparklePoof, whimsyEnabled} from './whimsy';

export default {
  mounted() {
    let dragged;
    const hook = this;

    const selector = '#' + this.el.id;

    document.querySelectorAll('.dropzone').forEach((dropzone) => {
      new Sortable(dropzone, {
        animation: 0,
        delay: 50,
        delayOnTouchOnly: true,
        group: 'shared',
        draggable: '.draggable',
        ghostClass: 'sortable-ghost',
        onEnd: function (evt) {
          hook.pushEventTo(selector, 'move-pear', {
            from: evt.from.id,
            pear: evt.item.id,
            to: evt.to.id,
          });

          if (whimsyEnabled() && evt.to.id !== 'Removed') {
            const rect = evt.item.getBoundingClientRect();
            sparklePoof(rect.left + rect.width / 2, rect.top + rect.height / 2);
          }
        },
      });
    });
  },
};
