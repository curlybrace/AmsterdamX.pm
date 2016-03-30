/*Core*/
var Basis = {
    hasClass: function(target, classValue) {
        var pattern = new RegExp('(^| )' + classValue + '( |$)');
        return (pattern.test(target.className)); //True or False
    },
    
    addClass: function(target, classValue) {
        if(!Basis.hasClass(target, classValue)) {
            classValue = (target.className=='') ? classValue : (' '+classValue);
            target.className += classValue;
        } 
    },

    removeClass: function(target, classValue) {
        if (Basis.hasClass(target, classValue)) {
            var pattern = new RegExp('(\\s|^)' + classValue + '(\\s|$)');
            target.className = target.className.replace(pattern, '');
        }
    },

    getElementsByClass: function(classValue, parentEl) {
        var allElements = (arguments.length>1) ?
                          parentEl.getElementsByTagName('*') :
                          document.body.getElementsByTagName('*'),
            matchedElements = [],
            pattern = new RegExp('(^| )' + classValue + '( |$)');

        for (var i=0, l=allElements.length; i<l; i++) {
            if(pattern.test(allElements[i].className)) {
                matchedElements[matchedElements.length] = allElements[i];
            }
        }
        return matchedElements;
    },

    start: function(fn) {
        Basis.addEventListener(window, 'load', fn);
    }
};

/*w3c*/
if (document.addEventListener) {
    Basis.addEventListener = function(target, type, listener) {
        target.addEventListener(type, listener, false);
    };

    Basis.removeEventListener = function(target, type, listener) {
        target.removeEventListener(type, listener, false);
    };

    Basis.preventDefault = function(event) {
        event.preventDefault();
    };

    Basis.stopPropagation = function(event) {
        event.stopPropagation();
    };
}

/*IE*/
else if (document.attachEvent) {
    Basis.addEventListener = function(target, type, listener) {
        if (Basis._findListener(target, type, listener) != -1) {
            return;
        }
        var listener2 = function() {
            var event = window.event;

            if (Function.prototype.call) {
                listener.call(target, event);
            }
            else {
                target._currentListener = listener;
                target._currentListener(event);
                target._currentListener = null;
            }
        };

        target.attachEvent('on' + type, listener2);

        var listenerRecord = {
            target: target,
            type: type,
            listener: listener,
            listener2: listener2
        };

        var targetDocument = target.document || target;
        var targetWindow = targetDocument.parentWindow;
        
        var listenerId = 'l' + Basis._listenerCounter++;

        if (!targetWindow._allListeners) {
            targetWindow._allListeners = {};
        }
        targetWindow._allListeners[listenerId] = listenerRecord;

        if (!target._listeners) { 
            target._listeners = [];
        }
        target._listeners[target._listeners.length] = listenerId;

        if (!targetWindow._unloadListenerAdded) {
            targetWindow._unloadListenerAdded = true;
            targetWindow.attachEvent('onunload', Basis._removeAllListeners);
        }
    };

    Basis.removeEventListener = function(target, type, listener) {
        var listenerIndex = Basis._findListener(target, type, listener);
        if (listenerIndex == -1) {
            return;
        }

        var targetDocument = target.document || target;
        var targetWindow = targetDocument.parentWindow;

        var listenerId = target._listeners[listenerIndex];
        var listenerRecord = targetWindow._allListeners[listenerId];

        target.detachEvent('on' + type, listenerRecord.listener2);
        target._listeners.splice(listenerIndex, 1);

        delete targetWindow._allListeners[listenerId];
    };

    Basis.preventDefault = function(event) {
        event.returnValue = false;
    };

    Basis.stopPropagation = function(event) {
        event.cancelBubble = true;
    };

    Basis._findListener = function(target, type, listener) {
        var listeners = target._listeners;
        if (!listeners) { 
            return -1;
        }

        var targetDocument = target.document || target;
        var targetWindow = targetDocument.parentWindow;

        for (var i = listeners.length - 1; i >= 0; i--) {
            var listenerId = listeners[i];
            var listenerRecord = targetWindow._allListeners[listenerId];

            if (listenerRecord.type == type && listenerRecord.listener == listener) {
                return i;
            }
        }
        return -1;
    };

    Basis._removeAllListeners = function() {
        var targetWindow = this;
        for (id in targetWindow._allListeners) {
            var listenerRecord = targetWindow._allListeners[id];
            listenerRecord.target.detachEvent('on' + listenerRecord.type, listenerRecord.listener2);
            delete targetWindow._allListeners[id];
        }
    };

    Basis._listenerCounter = 0;
}
/*end IE*/
/*end Core*/

/*Amsterdam XXX*/
var XXX = {
    init: function() {
        //don't bother running if screen is size of mouse turd
        var width = document.body.clientWidth;
        if (width < 600) {return;}

        //top menu smoothscroll setup
        //assume tt has set class of 'current' on current page link
        var container = Basis.getElementsByClass('container')[0],
            navLinks = document.getElementsByTagName('NAV')[0].getElementsByTagName('UL')[0].getElementsByTagName('A'),
            navLen = navLinks.length,
            navHeight = document.getElementsByTagName('NAV')[0].clientHeight,
            aboutLink,
            currentPage,
            footer = document.getElementById('footer');

        for (var link=0;link<navLen;link++) {
            //track current page highlight
            if (Basis.hasClass(navLinks[link], 'current')) {
                currentPage = navLinks[link];
            }
            //track which one goes to footer
            if (navLinks[link].href.indexOf('#footer') != -1) {
                aboutLink = navLinks[link];
            }
            navLinks[link].onclick = function() { 
                //what if more in-page links are added?
                //clear all current classes
                XXX.clearClasses(navLinks, navLen);
                Basis.addClass(this, 'current');
            };
        } 

        //back to top thingie
        var topAnchor = document.createElement('a'),
            toTopText = document.createTextNode('Back to top');
        topAnchor.href = '#top';
        topAnchor.id = 'toTop';
        container.appendChild(topAnchor).appendChild(toTopText);
      
        //in-page links smoothscroll + avoid stickynav
        var pageLinks = document.getElementsByTagName('A'),
            pageLen = pageLinks.length;
        for (var i=0;i<pageLen;i++) {
            pageLinks[i].onclick = function(e) { 
                if (this.hash) {
                    XXX.smoothScroll(this, e, navHeight);
                    window.location.hash='';
                }
            }
        }

        //scrolly footery stuff...
        var viewportHeight = Math.max(
                document.documentElement.clientHeight,
                window.innerHeight || 0),
            currentPosition = 0;

        //listen for scroll, to deal with back to top and footer
        Basis.addEventListener(window, 'scroll', function() {
            var wait;        
            clearTimeout(wait);
            wait = setTimeout(function() {
                currentPosition = XXX.getYPosition();
                XXX.dealWithToTop(currentPosition, topAnchor);
                XXX.dealWithFooter(footer, viewportHeight, currentPage, aboutLink);
            }, 600);
        });
    },
//end init()

    clearClasses: function(mainLinks, length) {
        while (length--) {
            Basis.removeClass(mainLinks[length], 'current');
        }
    },

    smoothScroll: function(anchor, event, navHeight) {
        var address = anchor.hash.substr(1),
            destination = document.getElementById(address);

        if (!destination) {
            return true;
        }

        var destinationY = destination.offsetTop;
        while (destination.offsetParent &&
            (destination.offsetParent != document.body)) {
            destination = destination.offsetParent;
            destinationY += destination.offsetTop;
        }
  
        clearInterval(interScroll);
      
        var currentYpos = XXX.getYPosition(),
            stepsize = parseInt((destinationY - currentYpos) / 50, 10);

        function scrollWindow() {
            var oldYpos = XXX.getYPosition(),
                isAbove = (oldYpos < destinationY);
            window.scrollTo(0, oldYpos + stepsize);
            var newYpos = XXX.getYPosition(),
                isAboveNow = (newYpos < destinationY);
            if ((isAbove != isAboveNow) || (oldYpos == newYpos)) {
                window.scrollTo(0, (destinationY - navHeight));
                clearInterval(interScroll);
            }
        }
        var interScroll = setInterval(scrollWindow, 10);
      
        Basis.preventDefault(event);
        Basis.stopPropagation(event);
    },

    getYPosition: function() {
        if (window.pageYOffset) {
            return window.pageYOffset;
        }
        if (document.body.scrollTop) {
            return document.body.scrollTop;
        }
        return 0;
    },

    dealWithToTop: function(position, anchor) {
        if (position >= 200) {
            Basis.addClass(anchor, 'appear'); 
        }
        else {
            Basis.removeClass(anchor, 'appear'); 
        }
    },

    dealWithFooter: function(footer, viewportHeight, currentPage, aboutLink) {
        var docTop = (document.documentElement.scrollTop ? 
                      document.documentElement.scrollTop :
                      document.body.scrollTop),
            foot = footer,
            area,
            footerPos = foot.offsetTop;
        while (foot.offsetParent &&
            (foot.offsetParent != document.body)) {
            foot = foot.offsetParent;
            footerPos += foot.offsetTop;
        }
        area = parseInt(viewportHeight + docTop, 10);

        if (area >= footerPos) {
            Basis.removeClass(currentPage, 'current');
            Basis.addClass(aboutLink, 'current');
        }
        else {
            Basis.addClass(currentPage, 'current');
            Basis.removeClass(aboutLink, 'current');
        }
    }
};

Basis.start(XXX.init);
