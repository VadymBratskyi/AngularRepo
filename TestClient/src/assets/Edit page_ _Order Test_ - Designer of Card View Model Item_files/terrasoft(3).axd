// jscs:disable
/* jshint ignore:start */
/*ignore jslint start*/
Terrasoft = {Version: "0.0.1"};
isOldUI = true;

/**
  * Events of the child window (created from the current window), to which you can add handlers.
  */
window.childEvent = {
	/**
  * The child window document is loaded.
 */
	onDocumentReady : null
};

/**
  * Subscription manager for the child window events in the parent window. The child window checks for the presence of an event subscription via the 'opener' property, if there are handlers for the specified event, they will be called.
  * Can only be used for one-time events, such as `onDocumentReady`, since after an event occurs, all handlers are deleted.
  */
Terrasoft.ChildWindowEventsManager = {
	
	/**
   * Checks if there are subscribers for the events of the child window.
   * @param {Object} opener The object that initiated the opening of the window.
   * @private
   */
	hasChildEventHandlers: function(opener, event) {
		return !Ext.isEmpty(opener) && !Ext.isEmpty(opener.childEvent) && !Ext.isEmpty(opener.childEvent[event]);
	},

	/**
  * Adds an event handler. Call only in the parent window.
  * @param {String} event The name of the event.
  * @param {Function} handler The event handler.
  */
	addListener: function(event, handler) {
		if (typeof handler !== "function") {
			throw new "'handler' is not a function";
		}
		var events = window.childEvent
		var handlers = events[event] = events[event] || [];
		handlers.push(handler);
	},

	/**
  * Initiates the event in the child window, after executing the handlers, deletes them. Should be called only in the child window.
  * @param {String} event The name of the event.
  */
	trigger: function(event) {
		var opener = window.opener;
		if (this.hasChildEventHandlers(opener, event)) {
			var handlers = opener.childEvent[event];
			var handler;
			while (handler = handlers.pop()) {
				handler();
			}
		}
	}
};

Ext.onReady(function () {
	var opener = window.opener;
	if (typeof opener == "object" && opener) {
		// Fix. FF16 XSS Security exception. Need to continue js scenario execution for newly opened window. 
		var isOldUI = false;
		if (Ext.isGecko) {
			try {
				isOldUI = (opener.isOldUI === true);
			} catch(e) {
				console.log(e.toString());
			}
		} else {
			isOldUI = (opener.isOldUI === true);
		}
		window.mainPage = isOldUI ? (opener.mainPage || opener) : window;
		Terrasoft.ChildWindowEventsManager.trigger("onDocumentReady");
	}
	// Hack. window.document.body.offsetHeight can be used after IE parses the BODY tag
	setTimeout(function() {
		window.startInnerWidth = window.document.body.offsetWidth;
		window.startInnerHeight = window.document.body.offsetHeight;
	}, 100);
});

Terrasoft.ScriptLoader = function() {

	var cleanupScriptElement = function(script) {
		script.onload = null;
		script.onreadystatechange = null;
		script.onerror = null;
		return this;
	};

	var injectScriptElement = function(url, onLoad, onError, scope) {
		var script = document.createElement('script');
		var onLoadFn = function() {
			cleanupScriptElement(script);
			onLoad.call(scope);
		};
		var onErrorFn = function() {
			cleanupScriptElement(script);
			onError.call(scope);
		};
		script.type = 'text/javascript';
		script.src = url;
		script.onload = onLoadFn;
		script.onerror = onErrorFn;
		script.onreadystatechange = function() {
			if (this.readyState === 'loaded' || this.readyState === 'complete') {
				onLoadFn();
			}
		};
		Ext.getDoc().dom.getElementsByTagName('head')[0].appendChild(script);
		return script;
	};

	return {
		loadScript: function(scriptUrl, onLoad, onError, scope) {
			scope = scope || this;
			this.isLoading = true;
			if (!Ext.isReady && Ext.onDocumentReady) {
				Ext.onDocumentReady(function() {
					injectScriptElement(scriptUrl, onLoad, onError, scope);
				});
			} else {
				injectScriptElement(scriptUrl, onLoad, onError, scope);
			}
		}
	};
}();

Terrasoft.getDevice = function() {
	var flags;
	var get = function() {
		if (!flags) {
			flags = {
				isMobile: false,
				isDesktop: false
			};
			var names = {
				ios: 'iOS',
				android: 'Android',
				webos: 'webOS',
				blackberry: 'BlackBerry',
				rimTablet: 'RIMTablet',
				mac: 'MacOS',
				win: 'Windows',
				linux: 'Linux',
				bada: 'Bada',
				other: 'Other'
			};
			var prefixes = {
				ios: 'i(?:Pad|Phone|Pod)(?:.*)CPU(?: iPhone)? OS ',
				android: 'Android ',
				blackberry: 'BlackBerry(?:.*)Version\/',
				rimTablet: 'RIM Tablet OS ',
				webos: '(?:webOS|hpwOS)\/',
				bada: 'Bada\/'
			};
			var userAgent = navigator.userAgent, osName,
				i, prefix, match;
			for (i in prefixes) {
				if (prefixes.hasOwnProperty(i)) {
					prefix = prefixes[i];
					match = userAgent.match(new RegExp('(?:'+prefix+')([^\\s;]+)'));
					if (match) {
						osName = names[i];
						break;
					}
				}
			}
			if (!osName) {
				osName = names[(userAgent.toLowerCase().match(/mac|win|linux/) || ['other'])[0]];
			}
			if (/Windows|Linux|MacOS/.test(osName)) {
				flags.isDesktop = true;
			} else {
				flags.isMobile = true;
			}
		}
		return flags;
	};
	return get;
}();

Terrasoft.getBrowser = function() {
	var browserInfo;

	function browserDetectNav() {
		var ua = window.navigator.userAgent;
		var operaRe = /(Opera|OPR)[\/ ]([\w.\/]+)/i;
		var chromeRe = /(Chrome)\/([\w.\/]+)/i;
		var safariRe = /(Safari)\/([\w.\/]+)/i; // must not contain 'Chrome'
		var firefoxRe = /(Firefox)\/([\w.\/]+)/i; // mus not contain 'Opera'
		var ieRe = /(?:(MSIE) |(Trident)\/.+rv:)([\w.]+)/i; // must not contain 'Opera'
		var versionRe = /(Version)\/([\w.\/]+)/i; // match for browser version
		var versionSplit = /[\/\.]/i;
		// WARNING! Order is important here!
		var match =
			ua.match(operaRe) || ua.match(chromeRe) || ua.match(safariRe) || ua.match(firefoxRe) || ua.match(ieRe);
		if (!match) {
			return false;
		}
		if (Array.prototype.filter) {
			match = match.filter(function(item) {
				return (item != null);
			});
		} else {
			// Hello, IE8!
			for (var j = 0; j < match.length; j++) {
				var matchGroup = match[j];
				if (matchGroup == null || matchGroup == '') {
					match.splice(j, 1);
					j--;
				}
			}
		}
		var name = match[1].replace('Trident', 'MSIE').replace('OPR', 'Opera');
		var versionMatch = ua.match(versionRe) || match;
		var version = versionMatch[2].split(versionSplit);
		return [name].concat(version);
	}

	function browserDetectJS() {
		var browser = [];
		// Opera is defined as Opera only for older versions up to 12 inclusive, when the Presto engine was used.
		// For Opera, the WebKit engine will return that it's Chrome
		if (window.opera) {
			browser[0] = "Opera";
			browser[1] = window.opera.version();
		} else if (window.chrome) {
			browser[0] = "Chrome";
		} else if (window.sidebar) {
			browser[0] = "Firefox";
		} else if ((!window.external) && (browser[0] !== "Opera")) {
			browser[0] = "Safari";
		} else if (Object.hasOwnProperty.call(window, "ActiveXObject")) {
			browser[0] = "MSIE";
		}
		if (Object.hasOwnProperty.call(window, "ActiveXObject") && !window.ActiveXObject) {
			browser[1] = "11";
		} else if (window.navigator.userProfile) {
			browser[1] = "6";
		} else if (window.Storage) {
			browser[1] = "8";
		} else if ((!window.Storage) && (!window.navigator.userProfile)) {
			browser[1] = "7";
		} else {
			browser[1] = "Unknown";
		}
		return browser;
	}

	function getBrowserInfo() {
		var browserNav = browserDetectNav();
		var browserJS = browserDetectJS();
		if (browserNav[0] == browserJS[0]) {
			return browserNav;
		} else if (browserNav[0] != browserJS[0]) {
			return browserJS;
		} else {
			return false;
		}
	}

	return function() {
		if (!browserInfo) {
			var browser = getBrowserInfo();
			browserInfo = {
				browserName: browser[0],
				version: parseFloat(browser[1] + '.' + browser[2]),
				arrayVersion: browser.slice(1)
			};
		}
		return browserInfo;
	};
}();

Terrasoft.Counter = function(name, isStarted) {
	this.name = name;
	this.isStarted = (isStarted === true);
	if (isStarted === true) {
		this.start();
	}
};

Terrasoft.Counter.prototype = {
	callsCount: 0,
	avgTime: 0,
	time: 0,

	formatTime: function (time) {
		time = new Date(time);
		var timeTemplate = '{0}m:{1}s:{2}ms';
		var formattedStartTime = String.format(timeTemplate, time.getMinutes(), time.getSeconds(),
			time.getMilliseconds());
		return formattedStartTime;
	},

	start: function() {
		this.callsCount = this.callsCount + 1;
		this.startTime = new Date().valueOf();
	},

	stop: function() {
		var finishTime = this.finishTime = new Date().valueOf();
		var elapsedTime = finishTime - this.startTime;
		var time = this.time = this.time + elapsedTime;
		this.avgTime = Math.floor(time / this.callsCount);
	},

	getValues: function() {
		var template = '{0}: calls = {1}; time = {2}ms; avgtime = {3}ms; start {4}; finish {5}';
		var startTime = this.formatTime(this.startTime);
		var finishTime = this.formatTime(this.finishTime);
		return String.format(template, this.name, this.callsCount, this.time, this.avgTime, startTime, finishTime);
	},

	clear: function() {
		this.callsCount = 0;
		this.avgTime = 0;
		this.time = 0;
	}
};

Terrasoft.PerformanceCounterManager = function() {
	var counters = {};

	var performance = window.performance || window.mozPerformance || window.msPerformance ||
		window.webkitPerformance;

	var getTiming = function (timingStr) {
		var timing = (performance) ? performance.timing : null;
		return (!timing) ? 0 : timing[timingStr];
	}

	var addNavigationTiminigCounter = function(manager, counterName, startTime, finishTime) {
		var navigationStartCounter = manager.addCounter(counterName, false);
		navigationStartCounter.startTime = startTime;
		navigationStartCounter.finishTime = finishTime;
		navigationStartCounter.time = finishTime - startTime;
	}

	var addNavigationTimingInfo = function(manager) {
		if (!performance) {
			return '';
		}
		var navigationStart = getTiming('navigationStart');
		var requestStart = getTiming('requestStart');
		var responseEnd = getTiming('responseEnd');
		var loadEventEnd = getTiming('loadEventEnd');
		var onReady = manager.getCounter('onReady').finishTime;
		addNavigationTiminigCounter(manager, 'Server', navigationStart, responseEnd);
		addNavigationTiminigCounter(manager, 'Client(ResponseEnd - Load)', responseEnd, loadEventEnd);
		addNavigationTiminigCounter(manager, 'Client(Load - OnReady)', loadEventEnd, onReady);
		addNavigationTiminigCounter(manager, 'Client', responseEnd, onReady);
		addNavigationTiminigCounter(manager, 'Full Time', navigationStart, onReady);
	}

	return {

		profile: function(name, fn, scope) {
			if (!this.getCounter(name)) {
				this.addCounter(name);
			}
			this.startCounter(name);
			fn.call(scope || window);
			this.stopCounter(name);
		},

		addCounter: function(name, isStarted) {
			var counter = counters[name];
			return counter || (counters[name] = new Terrasoft.Counter(name, isStarted));
		},

		clearCounter: function(name) {
			var counter = counters[name];
			if (!counter) {
				return;
			}
			counter.clear();
		},

		startCounter: function(name) {
			var counter = counters[name] || this.addCounter(name, false);
			counter.start();
		},

		stopCounter: function(name) {
			var counter = counters[name];
			if (!counter) {
				return;
			}
			counter.stop();
		},

		getCounter: function(name) {
			return counters[name];
		},

		getCounterValues: function(name) {
			var counter = counters[name];
			if (!counter) {
				return '';
			}
			return counter.getValues();
		},

		getProfileInfo: function(name) {
			if (name !== undefined) {
				return this.getCounterValues(name);
			}
			var value = [];
			addNavigationTimingInfo(this);
			for (var counter in counters) {
				if (counters.hasOwnProperty(counter)) {
					counter = counters[counter];
					value.push(counter.getValues());
				}
			}
			return value.join('\n');
		},

		clearProfileInfo: function(name) {
			if (name !== undefined) {
				return this.clearCounter(name);
			}
			for (var counter in counters) {
				if (counters.hasOwnProperty(counter)) {
					counter = counters[counter];
					counter.clear();
				}
			}
		}
	};
} ();

Terrasoft.registerCacheInfo = function(sender, windowName, treegrid) {
	if (!sender.cacheInfo) {
		sender.cacheInfo = [];
	}
	sender.cacheInfo[windowName] = { treegrid: treegrid };
};

Terrasoft.parseURLParams = function(urlParams) {
	if (!urlParams) {
		return '';
	}
	var comma = false;
	var result = '';
	for (var item in urlParams) {
		switch (typeof urlParams[item]) {
			case "object":
			case "undefined":
			case "function":
			case "unknown":
				break;
			default:
				if (comma) {
					result += ',' + item + '=' + urlParams[item];
				} else {
					comma = true;
					result = item + '=' + urlParams[item];
				}
		}
	}
	return result;
};

Terrasoft.openWindow = function(windowUrl, id, requestParams, width, height, isCenterWindow,
	showBrowserPopupWindowToolbars, openInExistingWindow, openWindowCallback, ignoreRequestId, windowName, useApplicationPath,
	config) {
	// TODO: try\catch используется только для IE, т.к. он генерирет ошибку "Отказано в доступе"

	// when trying to access the window reference, if the window is closed
	var availWidth = screen.availWidth;
	var availHeight = screen.availHeight;
	var left = 0;
	var top = 0;
	var isSchema = id;
	var windowURL = windowUrl;
	if (useApplicationPath == undefined || useApplicationPath === true) {
		windowURL = windowUrl.indexOf('http') != -1 ? windowUrl : Terrasoft.applicationPath + '/' + windowUrl;
	}
	var windowID = '_blank';
	var windowProfileUId;
	var customWindowId = '';
	showBrowserPopupWindowToolbars = false;
	var openInTab = (!width && !height && !openInExistingWindow && !windowName);
	var open = function() {
		if (id && id != '') {
			if (ignoreRequestId !== true) {
				windowURL += '?Id=' + id;
			}
			windowProfileUId = id;
			if (openInExistingWindow === true) {
				windowID = 'N' + id.toString().replace( /-/g , '');
			}
			if (ignoreRequestId === true) {
				id = undefined;
			}
		}
		if (requestParams && requestParams != '') {
			var first = true;
			for (var i = 0; i < requestParams.length; i++) {
				if (first) {
					if (!id || id == '') {
						windowURL += '?';
					} else {
						windowURL += '&';
					}
				} else {
					windowURL += '&';
				}
				var item = requestParams[i];
				windowURL += item.name + '=' + encodeURIComponent(item.value);
				if (item.name.toLowerCase() == 'id') {
					isSchema = true;
					if (!windowProfileUId) {
						windowProfileUId = item.value;
					}
					if (openInExistingWindow === true) {
						windowID = 'N' + item.value.toString().replace( /-/g , '');
					}
				} else if (item.name.toLowerCase() == 'customwindowid') {
					customWindowId = item.value.toString().replace( /-/g , '');
				}
				first = false;
			}
		}
		if (config && config.ignoreProfile) {
			windowProfileUId = null;
		}
		if (windowName && windowName !== '') {
			windowID = windowName;
		}
		var toolbarShow = showBrowserPopupWindowToolbars !== false ? 'yes' : '';
		var windowParams = '';
		if (toolbarShow == 'yes') {
			windowParams += 'menubar=' + toolbarShow;
			windowParams += ',titlebar=' + toolbarShow;
			windowParams += ',toolbar=' + toolbarShow;
			windowParams += ',scrollbars=auto';
			windowParams += ',status=' + toolbarShow;
			windowParams += ',location=' + toolbarShow;
		}
		windowParams += ',resizable';
		if (Ext.isSafari) {
			windowParams += ',chrome=yes';
		}
		if (!width || !height) {
			width = availWidth - 1;
			height = availHeight - 1;
		}
		var openWindow = function(o) {
			if (o) {
				width = o.width;
				height = o.height;
			}
			if (isCenterWindow !== false && width && height) {
				left = (availWidth - width) / 2;
				top = (availHeight - height) / 2;
			}
			if (width >= screen.availWidth) {
				width = screen.availWidth - 1;
				left = 0;
			}
			if (height >= screen.availHeight) {
				height = screen.availHeight - 1;
				top = 0;
			}
			left = Math.floor(left);
			top = Math.floor(top);
			if (!Ext.isEmpty(windowParams)) {
				windowParams += ', ';
			}
			if (Ext.isGecko) {
				windowParams += 'innerWidth=' + width + ',innerHeight=' + height;
			} else {
				windowParams += 'width=' + width + ',height=' + height;
			}
			windowParams += ',left=' + left + ',top=' + top;
			// TODO: убрать добавление параметра - это только для определения окон которые не передают windowProfileUId
			if (!windowProfileUId && isSchema) {
				if (windowURL.indexOf('?') == -1) {
					windowURL += '?';
				} else {
					windowURL += '&';
				}
				windowURL += 'ProfileEnabled=false';
			}
			var isSafari = Terrasoft.getBrowser().browserName.toLowerCase() == 'safari';
			// HACK: Проверка на Popup Blocker для кросс-доменных запросов
			var urlOriginRegex = /^((?:(?:https?|ftp):\/\/)?(?:[-A-Z0-9.]+)?(?::[0-9]+)?)(?:\/[-A-Z0-9+&@#\/%=~_|!:,.;]*)?(?:\?[-A-Z0-9+&@#\/%=~_|!:,.;]*)?/i;
			var currentLocation = document.location;
			var currentOrigin = currentLocation.origin;
			if (!currentOrigin) {
				var currentOriginMatch = urlOriginRegex.exec(currentLocation.href);
				currentOrigin = currentOriginMatch && currentOriginMatch.length > 1 ? currentOriginMatch[1] : null;
			}
			var targetOriginMatch = urlOriginRegex.exec(windowURL);
			var targetOrigin = targetOriginMatch && targetOriginMatch.length > 1 ? targetOriginMatch[1] : null;
			var isSameOrigin = !targetOrigin || targetOrigin.length == 0 || targetOrigin == currentOrigin;
			var result;
			if (openInTab) {
				result = window.open(windowURL);
			} else
			if (isSameOrigin) {
				result = window.open(windowURL, windowID, windowParams);
			} else {
				result = window.open(null, windowID, windowParams);
			}
			if (result && isSameOrigin) {
				if (Ext.isWebKit) {
					result.startWidth = width;
					result.startHeight = height;
				}
				if (Ext.isIE || isSafari) {
					try {
						result.resizeTo(width, height);
					} catch(e) {
					}
					try {
						result.moveTo(left, top);
					} catch(e) {
					}
				}
				if (Ext.isIE) {
					try {
						setTimeout(function() {
							if (result && result.closed === false) {
								result.startWidth = width;
								result.startHeight = height;
								if (Ext.isIE9 && windowProfileUId != undefined) {
									result.customWindowId = customWindowId;
									result.windowProfileUId = windowProfileUId;
								}
							}
						}, 2000);
					} catch(e) {
					}
				}
				if (!Ext.isIE9 && windowProfileUId != undefined) {
					try {
						result.customWindowId = customWindowId;
						result.windowProfileUId = windowProfileUId;
					} catch(e) {
					}
				}
			}
			var blockedPopupId = 'blockedPopup';
			var showBlockedPopupMessage = function(vmp) {
				if (vmp) {
					var stringList = Ext.StringList('WC.Common');
					vmp.remove(blockedPopupId);
					message = Ext.Link.applyLinks(stringList.getValue('FormValidator.PopupBlockedMessage'));
					vmp.addMessage(blockedPopupId, stringList.getValue('FormValidator.PopupBlockedTitle'),
						message, 'warning');
				}
			};
			setTimeout(function() {
				var vmp = Ext.FormValidator.getVMP();
				if (!result) {
					showBlockedPopupMessage(vmp);
				} else {
					try {
						if (isSameOrigin) {
							Ext.EventManager.on(result, 'load', function() {
								setTimeout(function() {
									if (vmp) {
										if (result.innerHeight === 0 && !result.closed) {
											showBlockedPopupMessage(vmp);
										} else {
											vmp.remove(blockedPopupId);
										}
									}
								}, 1500);
							});
						} else {
							if (vmp) {
								if (result.outerHeight > 0 || result.closed) {
									vmp.remove(blockedPopupId);
								} else {
									showBlockedPopupMessage(vmp);
								}
							}
							result.location.replace(windowURL);
						}
					} catch(e) {
					}
				}
			}, 500);
			return result;
		};
		var options;
		if (window.profileWindowData && windowProfileUId) {
			options = window.profileData.getCachedWindowSize(windowProfileUId, customWindowId);
		}
		var createWindow = function() {
			var createdWindow = openWindow(options);
			if (openWindowCallback && createdWindow) {
				openWindowCallback(createdWindow);
			}
		};
		if (window.profileData && windowProfileUId && !options) {
			var browserString = window.profileData.getProfileBrowserString();
			window.profileData.getWindowProfileData(windowProfileUId, customWindowId, function(response) {
				if (!window.profileWindowData) {
					window.profileWindowData = [];
				}
				var xmlData = response.responseXML;
				var root = xmlData.documentElement || xmlData;
				var data = root.text || root.textContent;
				var serviceResult = Ext.decode(data);
				if (serviceResult !== true) {
					options = {
						width: serviceResult.width,
						height: serviceResult.height
					};
					window.profileWindowData.push({
						id: windowProfileUId,
						browserString: customWindowId + browserString,
						width: options.width,
						height: options.height
					});
				}
				createWindow();
			});
		} else {
			if (Ext.isIE) {
				setTimeout(createWindow, 10);
			} else {
				createWindow();
			}
		}
	};
	var getSystemSettingsValueResponse = function(code, value) {
		if (value && value.toLowerCase() === 'true') {
			showBrowserPopupWindowToolbars = true;
		}
		open();
	};
	var getSystemSettingsValueFilureResponse = function(code, value) {
		open();
	};
	Terrasoft.SystemSettings.getValue('ShowBrowserPopupWindowToolbars', getSystemSettingsValueResponse,
		getSystemSettingsValueFilureResponse);
};

Terrasoft.openEditWindow = function(windowName, attributes, urlParams) {
	var treegrid = attributes.treegrid;
	Terrasoft.registerCacheInfo(this, windowName, treegrid);
	var sw = screen.width;
	var sh = screen.height;
	var windowURL = windowName + '.aspx';
	var windowID = 'wnd_' + windowName;
	var windowParams = '';
	var parsedURLParams = Terrasoft.parseURLParams(urlParams);
	if (attributes.windowHeight) {
		windowParams += 'height=' + attributes.windowHeight + ',top=' +
			(sh - attributes.windowHeight) / 2 + ',';
	}
	if (attributes.windowWidth) {
		windowParams += 'width=' + attributes.windowWidth + ',left=' +
			(sw - attributes.windowWidth) / 2 + ',';
	}
	windowParams += 'location=no,toolbar=no,menubar=no,resizable=no,' +
		'scrollbars=no,status=no,dialog';
	var editWindow;
	if (attributes.isNew) {
		var URL = windowURL
		if (parsedURLParams != '') {
			URL += '?' + parsedURLParams;
		}
		editWindow = window.open(URL, windowID, windowParams);
		editWindow.treegrid = treegrid;
		editWindow.focus();
	} else {
		var selectedItems = treegrid.selModel.selections.items;
		if (selectedItems.length == 0) {
			return;
		}
		for (var i = 0; i < selectedItems.length; i++) {
			var selectedId = selectedItems[i].id;
			var URL = windowURL + '?Id=' + selectedId;
			if (parsedURLParams != '') {
				URL += ',' + parsedURLParams;
			}
			var ID = windowID + selectedId;
			ID = ID.replace(/-/g, "");
			ID = ID.replace(/{/g, "");
			ID = ID.replace(/}/g, "");
			editWindow = window.open(URL, ID, windowParams);
			editWindow.treegrid = treegrid;
			editWindow.focus();
		}
	}
};

Terrasoft.verticalPanelAlignment = function() {
	var clientHeight = this.body.dom.clientHeight;
	var window = this.body.dom.firstChild;
	var windowHeight = this.height;
	var clientTop = (clientHeight - windowHeight) / 2;
	if (clientTop < 0) {
		clientTop = 0;
	}
	if (Ext.isGecko) {
		this.body.dom.style.paddingTop = clientTop + 'px';
	} else {
		this.body.dom.style.pixelTop = clientTop;
	}
};

Terrasoft.ItemConfig = function() {
};

Terrasoft.ItemConfig.prototype = {
};

Ext.isEmptyObj = function(o) {
	if (!(!Ext.isEmpty(o) && typeof o == "object")) { return false; }
	for (var p in o) { return false; }
	return true;
};

Terrasoft.ToolButton = function(config) {
	Terrasoft.ToolButton.superclass.constructor.call(this, config);
};

Ext.extend(Terrasoft.ToolButton, Ext.LayoutControl, {
	baseCls: 'x-toolbutton',
	overCls: 'x-toolbutton-over',
	clickCls: 'x-toolbutton-click',
	disabledCls: 'x-toolbutton-disable',
	pressedCls: 'x-toolbutton-pressed',
	defaultImageCls: 'x-form-flash-toolbutton',
	pressed: false,
	enableToggle: false,
	autoEl: {
		tag: 'img'
	},

	initComponent: function() {
		Terrasoft.ToolButton.superclass.initComponent.call(this);
		this.addEvents('click', 'toggle', 'menuitemclick');
		if (typeof this.toggleGroup === 'string') {
			this.enableToggle = true;
		}
		if (this.menuConfig && this.menuConfig.length > 0) {
			this.ensureMenuCreated();
			this.menu.createItemsFromConfig(this.menuConfig);
		}
	},

	getMenu: function() {
		this.ensureMenuCreated();
		return this.menu;
	},

	ensureMenuCreated: function() {
		if (!this.menu) {
			this.menu = new Ext.menu.Menu({id:Ext.id()});
			this.menu.owner = this;
		}
	},

	insert: function(index, item) {
		this.ensureMenuCreated();
		return this.menu.insert(index, item);
	},

	removeControl: function(item) {
		if (!this.menu) {
			return;
		}
		this.menu.remove(item);
		this.onContentChanged();
		return item;
	},

	add: function() {
		this.ensureMenuCreated();
		return this.menu.add(item);
	},

	onContentChanged: function() {
	},

	onRender: function(container, position) {
		Terrasoft.ToolButton.superclass.onRender.call(this, container, position);
		this.el.dom.setAttribute('src', Ext.BLANK_IMAGE_URL);
		this.el.addClass(this.baseCls);
		this.el.addClassOnClick(this.clickCls);
		this.el.on("click", this.onClick, this);
		this.setImage();
		if (this.pressed) {
			this.el.addClass(this.pressedCls);
		}
		Ext.ButtonToggleMgr.register(this);
		if (this.hidden === true || this.visible === false) {
			this.setVisible(false);
		}
	},

	setImage: function(value) {
		var imageSrc;
		if (value == undefined) {
			if (!this.imageConfig || this.imageConfig.source == "None") {
				var cfg = this.imageCls || this.defaultImageCls;
				var oldImageCls = this.imageCls;
				this.imageCls = cfg;
				this.el.replaceClass(oldImageCls, cfg);
				return;
			}
		} else {
			this.imageConfig = value;
		}
		imageSrc = this.getImageSrc();
		imageSrc = !Ext.isEmpty(imageSrc) && imageSrc != Ext.BLANK_IMAGE_URL ? imageSrc : ''; 
		this.el.setStyle('background-image', imageSrc);
	},

	onShow: function() {
		this.el.dom.style.display = '';
	},

	onHide: function() {
		this.el.dom.style.display = 'none';
	},

	onEnable: function() {
		this.el.removeClass(this.disabledCls);
		this.el.dom.readOnly = false;
	},

	onDisable: function() {
		this.el.addClass(this.disabledCls);
		this.el.dom.readOnly = true;
	},

	onDestroy: function() {
		if (this.rendered) {
			Ext.ButtonToggleMgr.unregister(this);
		}
		Terrasoft.ToolButton.superclass.onDestroy.call(this);
	},

	onClick: function(e) {
		if (!this.enabled || e.button != 0 || this.designMode) return;
		if (this.menu && !this.menu.isVisible()) {
			this.menu.show(this.el, this.menuAlign);
			return;
		}
		if (this.enableToggle && (this.allowDepress !== false || !this.pressed)) {
			this.toggle();
		}
		this.fireEvent('click', this, e);
		if (this.handler) {
			this.handler.call(this.scope || this, this, e);
		}
	},

	toggle: function(state) {
		state = state === undefined ? !this.pressed : state;
		if (state != this.pressed) {
			if (state) {
				this.el.addClass(this.pressedCls);
				this.pressed = true;
				this.fireEvent("toggle", this, true);
			} else {
				this.el.removeClass(this.pressedCls);
				this.pressed = false;
				this.fireEvent("toggle", this, false);
			}
			if (this.toggleHandler) {
				this.toggleHandler.call(this.scope || this, this, state);
			}
		}
	}

});

Ext.reg("toolbutton", Terrasoft.ToolButton);

Ext.ButtonToggleMgr = function() {
	var groups = {};

	function toggleGroup(btn, state) {
		if (state) {
			var g = groups[btn.toggleGroup];
			for (var i = 0, l = g.length; i < l; i++) {
				if (g[i] != btn) {
					g[i].toggle(false);
				}
			}
		}
	}

	return {
		register: function(btn) {
			if (!btn.toggleGroup) {
				return;
			}
			var g = groups[btn.toggleGroup];
			if (!g) {
				g = groups[btn.toggleGroup] = [];
			}
			g.push(btn);
			btn.on("toggle", toggleGroup);
		},

		unregister: function(btn) {
			if (!btn.toggleGroup) {
				return;
			}
			var g = groups[btn.toggleGroup];
			if (g) {
				g.remove(btn);
				btn.un("toggle", toggleGroup);
			}
		}
	};

} ();

Terrasoft.Tools = function() {
};

Terrasoft.Tools.ToolbarCollection = function() {
	var table = document.createElement("table");
	table.className = "x-toolbar-collection";
	table.cellSpacing = 0;
	var row = document.createElement("tr");
	table.appendChild(row);
	this.el = Ext.getDom(table);
	this.items = new Ext.util.MixedCollection(false, function(item) {
			return item.id});
};

Terrasoft.Tools.ToolbarCollection.prototype =  {
		
		render: function(parentCt) {
			this.parentCt = parentCt;
			parentCt.appendChild(this.el);
			var items = this.items;
			for (var i=0; i<items.length; i++) {
				items.items[i].render(this.el);
			}
			this.rendered = true;
		},
		
		addItem: function(item, id, index) {
			var itemId = id || Ext.id();
			if (index >= 0) {
				this.items.insert(index, itemId, item);
			} else {
				this.items.add(itemId, item);
			}
			if (this.rendered) {
				item.render(this.el, index);
			}
		},
		
		removeItem: function(id) {
			var item = this.items.get(id);
			this.items.remove(item);
			item.destroy();
		},
		
		disable: function(){
			var items = this.items;
			for (var i=0; i<items.length; i++) {
				items.items[i].disable();
			}
			this.disabled = true;
		},
		
		enable: function(){
			var items = this.items;
			for (var i=0; i<items.length; i++) {
				items.items[i].enable();
			}
			this.disabled = false;
		}
};

Ext.reg('toolbarcollection', Terrasoft.Tools.ToolbarCollection);

Terrasoft.Tools.Toolbar = function(config) {
	this.owner = config.owner;
	this.id = config.id || Ext.id();
	var el = document.createElement("td");
	el.className = config.className;
	this.el = Ext.getDom(el);
	this.items = new Ext.util.MixedCollection(false, function(item) {
			return item.id});
};

Ext.extend(Terrasoft.Tools.Toolbar, Terrasoft.Tools.ToolbarCollection, {
	
	render: function(parentCt, index) {
		this.parentCt = parentCt;
		var targetNode = parentCt.firstChild;
		if ((index >= 0) && (index <= targetNode.children.length)) {
			var prevSibling = targetNode.children[index];
			targetNode.insertBefore(this.el, prevSibling);
		} else {
			targetNode.appendChild(this.el);
		}
		var items = this.items;
		for (var i=0; i<items.length; i++) {
			items.items[i].render(this.el);
		}
		this.rendered = true;
		this.afterRender();
	},
	
	destroy: function() {
		this.el.parentNode.removeChild(this.el);
	},
	
	clear: function() {
		var items = this.items;
		for (var i=items.length-1; i>=0; i--) {
			this.removeItem(items.keys[i]);
		}
	},
	
	afterRender: Ext.emptyFn
	
});

Ext.reg('toolbar', Terrasoft.Tools.Toolbar);

Terrasoft.Tools.Item = function(el) {
	this.el = Ext.getDom(el);
	this.id = Ext.id(this.el);
	this.hidden = false;
};

Terrasoft.Tools.Item.prototype = {

	getEl: function() {
		return this.el;
	},

	render: function(td) {
		this.td = td;
		td.appendChild(this.el);
	},

	destroy: function() {
		this.el.parentNode.removeChild(this.el);
	},

	show: function() {
		this.hidden = false;
		this.td.style.display = "";
	},

	hide: function() {
		this.hidden = true;
		this.td.style.display = "none";
	},

	setVisible: function(visible) {
		if (visible) {
			this.show();
		} else {
			this.hide();
		}
	},

	focus: function() {
		Ext.fly(this.el).focus();
	},

	disable: function() {
		if (this.td) {
			Ext.fly(this.td).addClass("x-item-disabled");
		}
		this.disabled = true;
		this.el.disabled = true;
	},

	enable: function() {
		if (this.td) {
			Ext.fly(this.td).removeClass("x-item-disabled");
		}
		this.disabled = false;
		this.el.disabled = false;
	}
};

Ext.reg('tbitem', Terrasoft.Tools.Item);

Terrasoft.Tools.Separator = function() {
	var s = document.createElement("img");
	s.className = "ytb-sep";
	s.src = Ext.BLANK_IMAGE_URL;
	Terrasoft.Tools.Separator.superclass.constructor.call(this, s);
};

Ext.extend(Terrasoft.Tools.Separator, Terrasoft.Tools.Item, {
	enable: Ext.emptyFn,
	disable: Ext.emptyFn,
	focus: Ext.emptyFn,
		
	show: function() {
		this.hidden = false;
		this.el.style.display = "";
	},

	hide: function() {
		this.hidden = true;
		this.el.style.display = "none";
	}
});

Ext.reg('tbseparator', Terrasoft.Tools.Separator);

Terrasoft.Tools.Container = function() {
	var el = document.createElement("div");
	el.className = "x-toolbar-container",
	Terrasoft.Tools.Container.superclass.constructor.call(this, el);
	this.items = new Ext.util.MixedCollection(false, function(o){
		return o.id});
};

Ext.extend(Terrasoft.Tools.Container, Terrasoft.Tools.Item, {
	addItem: function(item, id) {
		item.render(this.el);
		this.items.add(id, item);
	},
		
	removeItem: function(id) {
		var item = this.items.get(id);
		this.items.remove(item);
		item.remove();
	},
		
	clear: function(){
		var keys = this.items.keys;
		for (var i=keys.length-1; i>=0; i--) {
			this.removeItem(keys[i]);
		}
	},
		
	disable: function(){
		var filters = this.items;
		for (var i=0; i<filters.length; i++) {
			filters.items[i].disable();
		}
		this.disabled = true;
	},
		
	enable: function(){
		var filters = this.items;
		for (var i=0; i<filters.length; i++) {
			filters.items[i].enable();
		}
		this.disabled = false;
	}
});

Ext.reg('tbcontainer', Terrasoft.Tools.Container);

Terrasoft.Tools.QuickFilterItem = function(config) {
	Ext.apply(this, config);
	var el = document.createElement("div");
	el.className = "x-quick-filter-item";
	var innerHTML = new Ext.Template(
		'<img src={blankImage} class="x-qf-left-corner">',
		'<div class="x-qf-text">{columnCaption}: <b>{displayValue}</b></div>',
		'<img src={blankImage} class="x-qf-close-button">'
	);
	var dataSourceFilter = config.dataSourceFilter;
	var columnCaption = dataSourceFilter.leftExpression.caption;
	if (dataSourceFilter.useDisplayValue) {
		var lastDelimeterPosition = columnCaption.lastIndexOf('.');
		if (lastDelimeterPosition != -1) {
			columnCaption = columnCaption.substr(0, lastDelimeterPosition);
		}
	}
	var displayValue = this.getDisplayValue(dataSourceFilter);
	var filterConfig = {
		blankImage: Ext.BLANK_IMAGE_URL,
		columnCaption: Ext.util.Format.htmlEncode(columnCaption),
		displayValue: Ext.util.Format.htmlEncode(displayValue)
	};
	el.innerHTML = innerHTML.apply(filterConfig);
	Terrasoft.Tools.QuickFilterItem.superclass.constructor.call(this, el);
	if (config.filterClick) {
		this.filterField = Ext.get(el.children[1]);
		this.filterField.on("click", this.filterClickHandler.createDelegate(this), this);
	}
	this.trigger = Ext.get(el.lastChild);
	this.trigger.addClassOnOver('x-toolbutton-over');
	this.trigger.addClassOnClick('x-toolbutton-click');
	if (config.triggerClick) {
		this.trigger.on("click", this.triggerClickHandler.createDelegate(this), this);
	}
};

Ext.extend(Terrasoft.Tools.QuickFilterItem, Terrasoft.Tools.Item, {
	remove: function(){
		this.el.parentNode.removeChild(this.el);
	},
	
	destroy: function() {
		this.remove();
	},
		
	filterClickHandler: function(){
		if ((this.disabled !== true) && this.filterClick){
			this.filterClick();
		}
	},
		
	triggerClickHandler: function(){
		if ((this.disabled !== true) && this.triggerClick){
			this.triggerClick();
		}
	},
		
	disable: function(){
		this.disabled = true;
		this.filterField.addClass("x-item-disabled")
		this.trigger.addClass("x-toolbutton-disable");
	},
		
	enable: function(){
		this.disabled = false;
		this.filterField.removeClass("x-item-disabled")
		this.trigger.removeClass("x-toolbutton-disable");
	},
		
	setColumn: function(columnCaption) {
		var textNode = Ext.get(this.el).child("div.x-qf-text");
		textNode.dom.childNodes[0].nodeValue = columnCaption + ": ";
	},
		
	setValue: function(displayValue) {
		var textNode = Ext.get(this.el).child("div.x-qf-text");
		textNode = textNode.dom.childNodes[1].innerHTML = displayValue;
	},

	getDisplayValue: function(dataSourceFilter) {
		var rightExpression = dataSourceFilter.rightExpression;
		var displayValue, rightExpressionValue;
		if (rightExpression && rightExpression.expressionType == Terrasoft.Filter.ExpressionType.PARAMETER
			&& dataSourceFilter.rightExpression.parameterValues.length > 0) {
			rightExpressionValue = dataSourceFilter.rightExpression.parameterValues[0];
			displayValue = rightExpressionValue
				? rightExpressionValue.displayValue || rightExpressionValue.parameterValue
				: "";
			var dataValueType = rightExpression.dataValueType;
			var dataType = dataValueType.name;
			switch (dataType) {
				case "Date":
				case "DateTime":
					displayValue = Ext.util.Format.date(rightExpressionValue.parameterValue,
						Ext.util.Format.getDateFormat());
					break;
				case "Time":
					displayValue = Ext.util.Format.date(displayValue, Ext.util.Format.getTimeFormat());
					break;
				case "Float1":
				case "Float2":
				case "Float3":
				case "Float4":
				case "Money":
					var thousandSeparator = Terrasoft.CultureInfo.numberGroupSeparator;
					var decimalSeparator = Terrasoft.CultureInfo.decimalSeparator;
					var decimalPrecision = dataValueType.precision || 2;
					var parsedValue = Terrasoft.Math.parseValue(displayValue.replace(decimalSeparator, ".")
						.replace(thousandSeparator, ""));
					displayValue = parsedValue.toFixed(decimalPrecision).replace(".", decimalSeparator);
					break;
				default:
					break;
			}
		}
		if (Ext.isEmpty(displayValue)) {
			var stringList = Ext.StringList('WC.TreeGrid');
			displayValue = String.format("<{0}>", stringList.getValue("QuickFilter.EmptyValueCaption"));
		}
		return displayValue;
	},
	
	rerender: function() {
		var dataSourceFilter = this.dataSourceFilter;
		var columnCaption = dataSourceFilter.leftExpression.caption;
		var displayValue = this.getDisplayValue(dataSourceFilter);
		this.setColumn(columnCaption);
		this.setValue(displayValue);
	}
});

Ext.reg('tbqfitem', Terrasoft.Tools.QuickFilterItem);

Terrasoft.Tools.Item.prototype.getEl = function() {
	return Ext.get(this.el);
};

Terrasoft.BaseEdit = Ext.extend(Ext.form.TextField, {
	supportsCaption: true,
	supportsCaptionNumber: true,
	width: 150,
	autoSize: Ext.emptyFn,
	monitorTab: true,
	deferHeight: true,
	mimicing: false,
	useImage: true,
	enableAllTools: false,
	imageWidth: 19,
	inputType: 'text',
	toolsAutoEl: { tag: 'span', cls: 'x-form-tools' },
	toolCfg: {
		baseCls: 'x-edit-toolbutton',
		overCls: 'x-edit-toolbutton-over',
		clickCls: 'x-edit-toolbutton-click',
		disabledCls: 'x-edit-toolbutton-disable'
	},

	initComponent: function() {
		Terrasoft.BaseEdit.superclass.initComponent.call(this);
		this.addEvents(
			'dblclick',
			'primarytoolbuttonclick'
		);
		if (this.toolsConfig) {
			this.toolCfg.ownerCt = this;
			Ext.each(this.toolsConfig, function(tool, i) {
				Ext.apply(tool, this.toolCfg);
			}, this);
			this.initTools(this.toolsConfig);
			delete this.toolsConfig;
		}
	},

	setImage: function(value) {
		this.imageConfig = value;
		this.setImageClass();
	},

	setImageClass: function(value) {
		if (!this.useImage) return;
		/*
		var imageCfg = {
			resourceManager: this.imageList,
			resourceId: this.imageId,
			resourceName: this.imageName,
			column: this.dataSource ? this.dataSource.getColumnByName(this.columnName) : null,
			? this.getValue() : null
		};
		*/
		var oldImageCls = this.imageCls;
		this.imageCls = value;
		if (!this.iconWrap) {
			this.iconWrap = this.wrap.createChild({
				tag: 'img',
				width: this.imageWidth,
				height: 18,
				src: Ext.BLANK_IMAGE_URL,
				cls: 'x-form-field-icon'
			});
			this.wrap.imageWidth = 0;
		}
		var imageSrc = this.getImageSrc();
		//var imgSrc = Ext.ImageUrlHelper.getImageUrl(imageCfg);
		if (!Ext.isEmpty(imageSrc) && imageSrc != Ext.BLANK_IMAGE_URL) {
			this.iconWrap.setStyle('background-image', imageSrc);
			this.iconWrap.setStyle('display', '');
		} else {
			this.iconWrap.replaceClass(oldImageCls, this.imageCls);
			this.iconWrap.setStyle('display', 'none');
		}
		//this.iconWrap.setStyle('display', (!Ext.isEmpty(imageSrc) || !Ext.isEmpty(this.imageCls)) ? '' : 'none');
		this.actualizeSize();
	},

	onRender: function(ct, position) {
		Terrasoft.BaseEdit.superclass.onRender.call(this, ct, position);
		this.wrap = this.el.wrap({ cls: "x-form-field-wrap" });
		this.toolsWrap = this.wrap.createChild(this.toolsAutoEl);
		if (this.tools && this.tools.length > 0) {
			for (var i = 0; i < this.tools.length; i++) {
				this.tools[i].render(this.toolsWrap);
			}
		}
		if (this.primaryToolButtonConfig) {
			this.primaryToolButtonWrap = this.wrap.createChild(this.toolsAutoEl);
			Ext.apply(this.primaryToolButtonConfig, this.toolCfg, { toolsWrap: this.primaryToolButtonWrap });
			var ptb = this.primaryToolButton = this.initTool(this.primaryToolButtonConfig);
			if (!this.designMode) {
				ptb.el.on('click', this.onPrimaryToolButtonClick, this);
			}
			this.onInitTool(ptb);
			delete this.primaryToolButtonConfig;
			if (this.hidePrimaryToolButton) {
				this.primaryToolButtonWrap.setDisplayed(false);
			}
		}
		this.el.on('dblclick', this.onDblClick, this);
		this.setImageClass(this.imageCls);
	},

	//private
	onToolBtnInsert: function(toolBtn) {
		Ext.apply(toolBtn, this.toolCfg);
		toolBtn.ownerCt = this;
		toolBtn.render(this.toolsWrap);
		this.onInitTool(toolBtn);
		this.actualizeSize();
	},

	insert: function(index, toolBtn, force) {
		if (!this.tools) {
			this.tools = [];
		}
		if (!toolBtn || !(toolBtn instanceof Terrasoft.ToolButton)) {
			// TODO Написать сообщение и вынести в ресурсы
			throw '';
		}
		toolBtn.ownerCt = this;
		this.tools.splice(index, 0, toolBtn);
		this.onToolBtnInsert(toolBtn);
	},

	add: function(toolBtn) {
		if (!this.tools) {
			this.tools = [];
		}
		if (!toolBtn || !(toolBtn instanceof Terrasoft.ToolButton)) {
			// TODO Написать сообщение и вынести в ресурсы
			throw '';
		}
		toolBtn.ownerCt = this;
		this.tools.push(toolBtn);
		this.onToolBtnInsert(toolBtn);
	},

	onContentChanged: function() {
		if (!this.tools) {
			this.tools = [];
		}
		this.actualizeSize();
	},
	
	moveControl: function(item, position) {
		var oldOwner = item.ownerCt;
		for (var i = 0, l = oldOwner.tools.length; i < l; i++) {
			if (oldOwner.tools[i].id == item.id) {
				if (!oldOwner.tools[i].el) {
					oldOwner.tools[i].onDestroy();
					Ext.ComponentMgr.unregister(oldOwner.tools[i]);
					oldOwner.tools[i].fireEvent("destroy", oldOwner.tools[i]);
					oldOwner.tools[i].purgeListeners();
				}
				else {
					item.rendered = true;
					oldOwner.getTool(i).destroy();
				}
				oldOwner.tools.splice(i, 1);
				oldOwner.actualizeSize();
				break;
			}
		}
		if (this.el) {
			item.rendered = false;
		}
		this.insert(position, item, true);
		Ext.ComponentMgr.register(item);
		Terrasoft.lazyInit([item.id]);
		this.actualizeSize();
	},
	
	removeControl: function(control) {
		if (!this.tools) {
			return;
		}
		for (var i = 0, l = this.tools.length; i < l; i++) {
			if (this.tools[i].id == control.id) {
				this.getTool(i).destroy();
				this.tools.splice(i, 1);
				this.actualizeSize();
				break;
			}
		}
	},

	selectControl: function(control) {
	},

	onInitTool: function(toolBtn) {
		toolBtn.on('click', this.onToolClick, this);
		toolBtn.on('hide', this.actualizeSize, this);
		toolBtn.on('show', this.actualizeSize, this);
	},
	
	onToolClick: function() {
		this.focus(false);
	},

	onPrimaryToolButtonClick: function(evt, el, o) {
		// TODO: разобраться с проверкой "o.t.enabled"
		if ((this.enabled) /*&& (o.t.enabled)*/) {
			this.fireEvent("primarytoolbuttonclick", this, o.t);
		}
	},

	onDblClick: function(e) {
		this.fireEvent("dblclick", this, e);
	},

	primaryToolButtonId: function() {
		return this.id ? this.id + '_PrimaryToolButton' : Ext.id();
	},

	setSize: function(w, h) {
		h = undefined;
		Terrasoft.BaseEdit.superclass.setSize.call(this, w, h);
	},

	onBlur: Ext.emptyFn,

	onResize: function(w, h) {
	},

	setValue: function(value, isInitByEvent, forceChangeEvent) {
		var oldValue = this.getRawValue();
		Terrasoft.BaseEdit.superclass.setValue.call(this, value);
		var value = this.checkSize(value || "");
		if ((value != oldValue && forceChangeEvent !== false) || forceChangeEvent === true) {
			this.fireChangeEvent(value, oldValue, isInitByEvent);
		}
	},

	fireChangeEvent: function(value, oldValue, isInitByEvent) {
		if (!this.valueInit) {
			return;
		}
		var opt = {
			isInitByEvent: isInitByEvent || false
		};
		this.startValue = value;
		this.fireEvent('change', this, value, oldValue, opt);
	},

	onFocus: function() {
		if (this.designMode) {
			return;
		}
		Terrasoft.BaseEdit.superclass.onFocus.call(this);
		if (!this.mimicing) {
			this.mimicing = true;
			Ext.get(Ext.isIE ? document.body : document).on("mousedown", this.mimicBlur, this, { delay: 10 });
			if (this.monitorTab) {
				this.el.on(Ext.isIE || Ext.isSafari3 ? "keydown" : "keypress", this.checkTab, this);
			}
		}
	},

	unFocus: function() {
		this.triggerBlur();
	},

	onDestroy: function() {
		if (this.tools) {
			Ext.each(this.tools, function(t) { t.destroy() });
			if (this.toolsWrap) {
				this.toolsWrap.remove();
			}
			delete this.tools;
		}
		if (this.primaryToolButton) {
			this.primaryToolButton.el.removeAllListeners();
			this.primaryToolButtonWrap.remove();
		}
		if (this.wrap) {
			this.wrap.remove();
		}
		Terrasoft.BaseEdit.superclass.onDestroy.call(this);
	},

	onDisable: function() {
		Terrasoft.BaseEdit.superclass.onDisable.call(this);
		this.wrap.addClass(this.disabledClass);
		this.enabled = false;
		if (this.primaryToolButton) {
			this.primaryToolButton.disable();
		}
		if (this.enableAllTools && this.tools) {
			for(var i =0; i<this.tools.length; i++) {
				this.tools[i].disable();
			}
		}
	},

	onEnable: function() {
		Terrasoft.BaseEdit.superclass.onEnable.call(this);
		this.wrap.removeClass(this.disabledClass);
		this.enabled = true;
		if (this.primaryToolButton) {
			this.primaryToolButton.enable();
		}
		if (this.enableAllTools && this.tools) {
			for(var i =0; i<this.tools.length; i++) {
				this.tools[i].enable();
			}
		}
	},

	checkTab: function(e) {
		if (e.getKey() == e.TAB) {
			this.triggerBlur();
		}
	},

	getTool: function(index) {
		return this.tools[index];
	},

	getResizeEl: function() {
		return this.captionWrap || this.wrap;
	},

	getPositionEl: function() {
		return this.captionWrap || this.wrap;
	},

	getActionEl: function() {
		return this.captionWrap || this.wrap;
	},

	mimicBlur: function(e) {
		if (!this.wrap.contains(e.target) && this.validateBlur(e)) {
			this.triggerBlur();
		}
	},

	triggerBlur: function() {
		this.mimicing = false;
		Ext.get(Ext.isIE ? document.body : document).un("mousedown", this.mimicBlur, this);
		if (this.monitorTab) {
			this.el.un("keydown", this.checkTab, this);
		}
		this.wrap.removeClass('x-toolbutton-wrap-focus');
		Terrasoft.BaseEdit.superclass.onBlur.call(this);
	},

	beforeBlur: Ext.emptyFn,

	validateBlur: function(e) {
		return true;
	},

	actualizeSize: function() {
		if (!this.rendered) {
			return;
		}
		var leftTextMargin = 4;
		var rightTextMargin = 4;
		var pToolBtn = this.primaryToolButton;
		var pToolBtnWidth = pToolBtn ? pToolBtn.el.getWidth() : 0;
		var visibleToolsWidth = 0;
		var wrap = this.wrap;
		var toolsWrap = this.toolsWrap;
		var iconWrap = this.iconWrap;
		var wrapWidthBefore = wrap.getWidth() == 0 ? (Ext.getCmp(this.id) ? Ext.getCmp(this.id).getWidth() : 0) : wrap.getWidth();
		if (this.tools) {
			visibleToolsWidth = toolsWrap.getWidth();
			toolsWrap.setStyle('right', toolsWrap.addUnits(pToolBtnWidth));
		}
		var wrapRightPadding = visibleToolsWidth + pToolBtnWidth + leftTextMargin + rightTextMargin;
		if (iconWrap) {
			if (iconWrap.isVisible() && wrap.imageWidth === 0) {
				wrap.imageWidth = this.imageWidth;
			} else if (!iconWrap.isVisible() && wrap.imageWidth > 0) {
				wrap.imageWidth = 0;
			}
		}
		wrap.setStyle('padding-left', wrap.addUnits(wrap.imageWidth));
		wrap.setStyle('padding-right', wrap.addUnits(wrapRightPadding));
		wrap.setWidth(wrapWidthBefore);
	}

});

Ext.reg('toolbuttonfield', Terrasoft.BaseEdit);

Ext.apply(Ext.lib.Ajax, {

	serializeForm: function(form) {
		if (typeof form == "string") {
			form = (document.getElementById(form) || document.forms[form]);
		}
		var el, name, val, disabled, data = "", hasSubmit = false;
		hasSubmit = form.ignoreAllSubmitFields || false;
		for (var i = 0; i < form.elements.length; i++) {
			el = form.elements[i];
			disabled = form.elements[i].disabled;
			name = form.elements[i].name;
			val = (name.search("__VIEWSTATE") != -1) ? form.elements[i].value : Ext.util.Format.htmlEncode(form.elements[i].value);
			if (!disabled && name) {
				switch (el.type) {
					case "select-one":
					case "select-multiple":
						for (var j = 0; j < el.options.length; j++) {
							if (el.options[j].selected) {
								if (Ext.isIE) {
									data += encodeURIComponent(name) + "=" + encodeURIComponent(el.options[j].attributes.value.specified ? el.options[j].value : el.options[j].text) + "&";
								} else {
									data += encodeURIComponent(name) + "=" + encodeURIComponent(el.options[j].hasAttribute("value") ? el.options[j].value : el.options[j].text) + "&";
								}
							}
						}
						break;
					case "radio":
						if (name !== val) {
							name += '_' + val;
						}
						data += encodeURIComponent(name) + "=" + encodeURIComponent(el.checked) + "&";
						break;
					case "checkbox":
						data += encodeURIComponent(name) + "=" + encodeURIComponent(el.checked) + "&";
						break;
					case "file":
					case undefined:
					case "reset":
					case "button":
						break;
					case "submit":
						if (hasSubmit === false) {
							data += encodeURIComponent(name) + "=" + encodeURIComponent(val) + "&";
							hasSubmit = true;
						}
						break;
					default:
						data += encodeURIComponent(name) + "=" + encodeURIComponent(val) + "&";
						break;
				}
			}
		}
		data = data.substr(0, data.length - 1);
		return data;
	}
});

Terrasoft.on = function(target, eventName, handler, scope, mode, cfg) {
	var el = target;
	if (typeof target == "string") {
		el = Ext.get(target);
	}
	if (!Ext.isEmpty(el)) {
		if (mode && mode == "client") {
			el.on(eventName, handler.fn, scope, handler);
		} else {
			el.on(eventName, handler, scope, cfg);
		}
	}
};

Ext.ns("Ext.ux.layout");

Ext.override(Ext.Component, {

	addPlugins: function(plugins) {
		if (Ext.isEmpty(this.plugins)) {
			this.plugins = [];
		} else if (!Ext.isArray(this.plugins)) {
			this.plugins = [this.plugins];
		}
		if (Ext.isArray(plugins)) {
			for (var i = 0; i < plugins.length; i++) {
				this.plugins.push(this.initPlugin(plugins[i]));
			}
		} else {
			this.plugins.push(this.initPlugin(plugins));
		}
	},

	getForm: function(id) {
		var form = Ext.isEmpty(id) ? this.el.up('form') : Ext.get(id);
		if (!Ext.isEmpty(form)) {
			Ext.apply(form, form.dom);
			form.submit = function() {
				form.dom.submit();
			};
		}
		return form;
	}
});

Ext.override(Ext.util.Observable, {

	init_ev: function() {
		if (!(this.isPostBackInit || false)) {
			this.isPostBackInit = true;
			if (this.postBacks) {
				this.on(this.postBacks);
			}
		}
		if (!(this.isAjaxInit || false)) {
			this.isAjaxInit = true;
			if (this.ajaxEvents) {
				this.on(this.ajaxEvents);
			}
		}
	}
});

Terrasoft.lazyInit = function(controls) {
	if (!Ext.isArray(controls)) { return; }
	for (var i = 0; i < controls.length; i++) {
		window[controls[i]] = Ext.getCmp(controls[i]);
	}
};

Terrasoft.controlLazyInit = function(control) {
	if (!control) {
		return;
	}
	window[control.id || control.proxyId] = control;
	var itemsArray = [];
	Terrasoft.containerLazyInit(control, itemsArray);
	Terrasoft.lazyInit(itemsArray);
};

Terrasoft.containerLazyInit = function(container, itemsArray) {
	if (!container.items || container.items.length == 0 || container.items.items == undefined) {
		return;
	}
	for (var i = 0; i < container.items.length; i++) {
		var item = container.items.items[i];
		itemsArray.push(item.id);
		Terrasoft.containerLazyInit(item, itemsArray);
	}
};

Terrasoft.setValues = function(controls) {
	if (!Ext.isArray(controls)) { return; }
	for (var i = 0; i < controls.length; i++) {
		if (!controls[i][0]) {
			continue;
		}
		controls[i][0].setValue(controls[i][1]);
	}
};

Terrasoft.doPostBack = function(config) {
	if (config.before) {
		if (config.before(config.control, config.extraParams || {}) === false) {
			return;
		}
	}
	if (config.extraParams) {
		var form = document.forms[0];
		if (!Ext.isEmpty(form)) {
			form = Ext.get(form);
			var id = "__TerrasoftPostBackParams";
			var el = form.insertFirst({ tag: "input", id: id, name: id, type: "hidden" });
			el.dom.value = Ext.encode(config.extraParams);
		}
	}
	config.fn();
};

Ext.namespace('Ext.ux.layout');

Ext.apply(Ext.form.VTypes, {

	daterange: function(val, field) {
		var date = field.parseDate(val);
		var dispUpd = function(picker) {
			var ad = picker.activeDate;
			if (ad) {
				picker.activeDate = null;
				picker.update(ad);
			}
		};
		if (field.startDateField) {
			var sd = Ext.getCmp(field.startDateField);
			sd.maxValue = date;
			if (sd.menu && sd.menu.picker) {
				sd.menu.picker.maxDate = date;
				dispUpd(sd.menu.picker);
			}
		} else if (field.endDateField) {
			var ed = Ext.getCmp(field.endDateField);
			ed.minValue = date;
			if (ed.menu && ed.menu.picker) {
				ed.menu.picker.minDate = date;
				dispUpd(ed.menu.picker);
			}
		}
		return true;
	}
});

if (!Ext.isIE6) {
	if (Ext.isIE) {
		Ext.util.CSS.createStyleSheet(".x-btn button{width:100%;}");
	}
	Ext.util.CSS.createStyleSheet(".x-form-radio-group .x-panel-body,.x-form-check-group .x-panel-body{background-color:transparent;}.x-form-cb-label-nowrap{white-space:nowrap;}");
}

Terrasoft.setTheme = function(url) {
	var token = "TERRASOFT_EXT_THEME";
	if (url === "Default") {
		Ext.util.CSS.removeStyleSheet(token);
	} else {
		Ext.util.CSS.swapStyleSheet(token, url);
	}
};

Terrasoft.getEl = function(el) {
	if (el.getEl) {
		return el.getEl();
	}
	var cmp = Ext.getCmp(el);
	if (!Ext.isEmpty(cmp)) {
		return cmp.getEl();
	}
	return Ext.get(el);
};

Terrasoft.loadWebMethod = function(serviceName, methodName, async) {
	var url = Terrasoft.getWebServiceUrl(serviceName, methodName);
	if (async == false) {
		Ext.asyncMode = false;
	}
	Ext.Ajax.request({
		cleanRequest: true,
		url: url,
		argument: {},
		params: ''
	});
	Ext.asyncMode = true;
};

Terrasoft.getWebServiceUrl = function(serviceName, methodName) {
	return String.format('{2}/{0}.asmx/{1}', serviceName, methodName, Terrasoft.applicationPath);
};

Terrasoft.Logout = function() {
	var getParam = function(doLogout) {
		var buf = [];
		var customDataFieldEl = Ext.get('customDataField');
		var customDataValue = '';
		if (customDataFieldEl) {
			customDataValue = Ext.decode(customDataFieldEl.dom.value);
			customDataValue.dataSourceCacheItemNames = Terrasoft.EntityDataSourceMgr.getDataSourceCacheItemNames();
		}
		buf.push("customData=", Ext.encode(customDataValue), '&');
		buf.push("doLogout=", Ext.encode(doLogout));
		return buf.join('');
	}

	return {
		invoke: function(doLogout, ajaxHandlers) {
			try {
				var successHandler = function(response) {
					if (ajaxHandlers && ajaxHandlers.successHandler && typeof ajaxHandlers.successHandler == 'function') {
						ajaxHandlers.successHandler(response);
					}
				}
				var failureHandler = function(response) {
					if (ajaxHandlers && ajaxHandlers.failureHandler && typeof ajaxHandlers.failureHandler == 'function') {
						ajaxHandlers.failureHandler(response);
					}
				}
				Ext.asyncMode = false;
				var serviceName = 'Services/ProfileService';
				var logoutMethodName = 'Logout';
				var url = Terrasoft.getWebServiceUrl(serviceName, logoutMethodName);
				Ext.Ajax.request({
					url: url,
					scope: this,
					success: successHandler,
					failure: failureHandler,
					params: getParam(doLogout)
				});
			} finally {
				Ext.asyncMode = true;
			}
		}
	}
}();

Terrasoft.SystemSettings = function() {
	var responseSystemSettingsValueCallback = function(response, request) {
		var xmlData = response.responseXML;
		if (xmlData) {
			var root = xmlData.documentElement || xmlData;
			var data = root.text || root.textContent;
			if (data) {
				Terrasoft.SystemSettings.cache[request.argument.code] = data;
			}
		}
		if (request.argument.responseCallback) {
			request.argument.responseCallback.call(request.objectScope, request.argument.code, data);
		}
	}
	var failureSystemSettingsValueCallback = function(response, request) {
		if (request.argument.failureCallback) {
			request.argument.failureCallback.call(request.scope, request.argument.code, response);
		}
	}
	
	return {

		cache: {},

		getValue: function(code, responseCallback, failureCallback, objectScope) {
			if (responseCallback == undefined) {
				return;
			}
			var value = Terrasoft.SystemSettings.cache[code];
			if (value) {
				responseCallback.call(objectScope, code, value);
				return;
			}
			var url = Terrasoft.getWebServiceUrl('Services/DataService', 'GetCurrentUserSettingsValue');
			Ext.Ajax.request({
				cleanRequest: true,
				url: url,
				success: responseSystemSettingsValueCallback,
				failure: failureSystemSettingsValueCallback,
				scope: this,
				objectScope: objectScope,
				argument: {code:code,responseCallback:responseCallback,failureCallback:failureCallback},
				params: 'code=' + code
			});
		},
		
		getValues: function(codes) {
			Ext.each(codes, function(code) {
				Terrasoft.SystemSettings.getValue(code, false);
			}, this);
		}
	}
}();

Terrasoft.LookupGridPage = function() {
	var internalKey;
	var internalSender;
	var schemaUId;
	var internalCallbackFunction;
	var internalReferenceSchemaUId;
	var internalReferenceSchemaList;
	var internalEditMode;
	var internalSearchValue;
	var internalUserContextUId;
	var internalMultiSelectMode;
	var getSystemSettingsValueResponse = function(code, value) {
		schemaUId = value;
		show();
	}
	var show = function() {
		if (internalReferenceSchemaList && internalReferenceSchemaList.length > 0) {
			for(var i = 0; i < internalReferenceSchemaList.length; i++) {
				if (internalReferenceSchemaList[i].referenceSchemaUId === internalReferenceSchemaUId) {
					internalReferenceSchemaList[i].isSourceSchemaUId = true;
					break;
				}
			}
			if (!internalReferenceSchemaUId) {
				internalReferenceSchemaUId = internalReferenceSchemaList[0].referenceSchemaUId;
			}
		}
		var windowUrl = 'ViewPage.aspx';
		var id = schemaUId;
		var requestParams = [];
		requestParams.push({name:'schemaUId', value: internalReferenceSchemaUId});
		if (internalEditMode) {
			requestParams.push({name:'editMode', value: internalEditMode});
		}
		if (internalSearchValue) {
			var internalSearchValueEncoded = Ext.util.Format.htmlEncode(internalSearchValue);
			requestParams.push({name:'searchValue', value: internalSearchValueEncoded});
		}
		if (internalUserContextUId) {
			requestParams.push({name:'tempUserContextUId', value: internalUserContextUId});
		}
		if (internalMultiSelectMode) {
			requestParams.push({name:'multiSelectMode', value: internalMultiSelectMode});
		}
		requestParams.push({name:'CustomWindowId', value: internalReferenceSchemaUId});
		var windowName = internalKey;
		Terrasoft.openWindow(windowUrl, id, requestParams, 600, 400, true, false, false, null, false, windowName);
		if (!window.lookupGridPageParams) {
			window.lookupGridPageParams = {};
		}
		window.lookupGridPageParams[internalKey] = {
			sender: internalSender,
			lookupGridPageCallback: internalCallbackFunction,
			referenceSchemaList: internalReferenceSchemaList,
			referenceSchemaUId: internalReferenceSchemaUId,
			editMode: internalEditMode
		}
	}

	return {
		show: function(key, sender, callbackFunction, referenceSchemaUId, referenceSchemaList, editMode, searchValue,
				userContextUId, lookupPageSchemaUId, multiSelectMode) {
			internalKey = key;
			internalSender = sender;
			internalCallbackFunction = callbackFunction;
			internalReferenceSchemaUId = referenceSchemaUId;
			internalReferenceSchemaList = referenceSchemaList;
			internalEditMode = editMode;
			internalSearchValue = searchValue;
			internalUserContextUId = userContextUId;
			internalMultiSelectMode = multiSelectMode;
			schemaUId = lookupPageSchemaUId;
			if (!schemaUId) {
				Terrasoft.SystemSettings.getValue('DefLookupGridPageSchemaUId', getSystemSettingsValueResponse);
				return;
			}
			show();
		}
	}
}();

Terrasoft.ProcessSchemaParameterValueEditPage = function () {
    var internalKey;
    var internalSender;
    var internalCallbackFunction;
    var internalUserContextUId;
    var internalReferenceSchemaUId;
    var internalReferenceSchemaManagerName;
    var internalDataValueTypeUId;
    var internalSource;
    var internalValue;
    var internalDisplayValue;
    var schemaUId;
    var internalMetaDataValue;
    var getSystemSettingsValueResponse = function(code, value) {
        schemaUId = value;
        show();
    };
    var show = function() {
        var windowUrl = 'ViewPage.aspx';
        var id = schemaUId;
        var requestParams = [];
        if (internalReferenceSchemaUId) {
            requestParams.push({name: 'EditSchemaUId', value: internalReferenceSchemaUId});
        }
        if (internalReferenceSchemaManagerName) {
            requestParams.push({name: 'EditSchemaManagerName', value: internalReferenceSchemaManagerName});
        }
        if (internalUserContextUId) {
            requestParams.push({name: 'tempUserContextUId', value: internalUserContextUId});
        }
        var windowName = internalKey;
        Terrasoft.openWindow(windowUrl, id, requestParams, 600, 400, true, false, false, null, false, windowName);
        if (!window.processSchemaParameterValueEditPageParams) {
            window.processSchemaParameterValueEditPageParams = {};
        }
        window.processSchemaParameterValueEditPageParams[internalKey] = {
            sender: internalSender,
            processSchemaParameterValueEditPageCallback: internalCallbackFunction,
            referenceSchemaUId: internalReferenceSchemaUId,
            referenceSchemaManagerName: internalReferenceSchemaManagerName,
            dataValueTypeUId: internalDataValueTypeUId,
            source: internalSource,
            value: internalValue,
            displayValue: internalDisplayValue,
            metaDataValue: internalMetaDataValue
        };
    };

    return {
        show: function(key, sender, callbackFunction, referenceSchemaUId, referenceSchemaManagerName, dataValueTypeUId,
            source, value, displayValue, editPageSchemaUId, userContextUId, metaDataValue) {
            internalKey = key;
            internalSender = sender;
            internalCallbackFunction = callbackFunction;
            internalReferenceSchemaUId = referenceSchemaUId;
            internalReferenceSchemaManagerName = referenceSchemaManagerName;
            internalDataValueTypeUId = dataValueTypeUId;
            internalUserContextUId = userContextUId;
            internalSource = source;
            internalValue = value;
            internalDisplayValue = displayValue;
            internalMetaDataValue = metaDataValue;
            schemaUId = editPageSchemaUId;
            if (!schemaUId) {
                Terrasoft.SystemSettings
                    .getValue('DefProcessSchemaParameterValueEditPageSchemaUId', getSystemSettingsValueResponse);
                return;
            }
            show();
        }
    };
}();

Terrasoft.ColumnEditPage = function() {
	var internalKey;
	var internalSender;
	var schemaUId;
	var internalCallbackFunction;
	var internalColumnId;
	var internalStructureExplorerId;
	var internalRootSchemaUId;
	var getSystemSettingsValueResponse = function(code, value) {
		schemaUId = value;
		show();
	};
	var show = function() {
		var windowUrl = 'ViewPage.aspx';
		var id = schemaUId;
		var requestParams = [];
		requestParams.push({ name: 'rootSchemaUId', value: internalRootSchemaUId });
		requestParams.push({ name: 'itemStoreKey', value: internalKey });
		var windowName = internalKey;
		Terrasoft.openWindow(windowUrl, id, requestParams, 600, 320, true, false, false, null, false, windowName);
		if (!window.columnEditPageParams) {
			window.columnEditPageParams = {};
		}
		window.columnEditPageParams[internalKey] = {
			sender: internalSender,
			columnEditPageCallback: internalCallbackFunction,
			columnId: internalColumnId,
			structureExplorerId: internalStructureExplorerId
		};
	};

	return {
		show: function(cfg) {
			if (typeof cfg == "string") {
				cfg = Terrasoft.ColumnEditPage[cfg];
				delete Terrasoft.ColumnEditPage[cfg.key];
			}
			schemaUId = cfg.pageSchemaUId;
			internalKey = cfg.key;
			internalSender = cfg.sender;
			internalCallbackFunction = cfg.callbackFunction;
			internalColumnId = cfg.columnId;
			internalStructureExplorerId = cfg.structureExplorerId;
			internalRootSchemaUId = cfg.rootSchemaUId;
			if (!schemaUId) {
				var schemaUIdSettingsName = cfg.isOppositeColumn
					? 'StructureExplorerAggColumnEditPageSchemaUId'
					: 'StructureExplorerColumnEditPageSchemaUId';
				Terrasoft.SystemSettings.getValue(schemaUIdSettingsName, getSystemSettingsValueResponse);
				return;
			}
			show();
		}
	};
}();

Terrasoft.ProfileData = function(profileId, key) {
	this.profileId = profileId;
	this.key = key;
	this.data = new Object();
};

Terrasoft.ProfileData.prototype = {
	serviceName: 'Services/ProfileService',
	saveMethodName: 'SaveProfileData',
	getWindowProfileMethodName: 'GetWindowProfileData',

	setData: function (controlId, key, data) {
		if (!this.data[controlId]) {
			this.data[controlId] = new Object();
		}
		this.data[controlId][key] = data;
	},

	getCachedWindowSize: function (windowProfileUId, customWindowId) {
		var options;
		browserString = customWindowId + this.getProfileBrowserString();
		Ext.each(window.profileWindowData, function (windowDataItem) {
			if (windowDataItem.id == windowProfileUId && browserString == windowDataItem.browserString) {
				options = {
					width: windowDataItem.width,
					height: windowDataItem.height
				};
				return false;
			}
		});
		return options;
	},

	setCachedWindowSize: function (windowProfileUId, windowCustomId, width, height) {
		browserString = windowCustomId + this.getProfileBrowserString();
		Ext.each(window.profileWindowData, function (windowDataItem) {
			if (windowDataItem.id == windowProfileUId && browserString == windowDataItem.browserString) {
				windowDataItem.width = width;
				windowDataItem.height = height;
				return false;
			}
		});
	},

	getWindowProfileData: function (windowProfileUId, customWindowId, successResponse) {
		var url = Terrasoft.getWebServiceUrl(this.serviceName, this.getWindowProfileMethodName);
		Ext.Ajax.request({
			url: url,
			success: successResponse,
			failure: this.handleFailure,
			scope: this,
			params: this.getWindowParams(windowProfileUId, customWindowId)
		});
	},

	save: function (ajaxHandlers) {
		var successHandler = function (response) {
			this.handleResponse(response);
			if (ajaxHandlers && ajaxHandlers.successHandler && typeof ajaxHandlers.successHandler == 'function') {
				ajaxHandlers.successHandler(response);
			}
		}
		var failureHandler = function (response) {
			this.handleFailure(response);
			if (ajaxHandlers && ajaxHandlers.failureHandler && typeof ajaxHandlers.failureHandler == 'function') {
				ajaxHandlers.failureHandler(response);
			}
		}
		var url = Terrasoft.getWebServiceUrl(this.serviceName, this.saveMethodName);
		try {
			Ext.asyncMode = false;
			Ext.Ajax.request({
				url: url,
				async: false,
				success: successHandler,
				failure: failureHandler,
				scope: this,
				params: this.getParams()
			});
		} finally {
			Ext.asyncMode = true;
		}
	},

	getProfileBrowserString: function () {
		if (Ext.isIE) {
			return "ie";
		} else if (Ext.isGecko) {
			return "gecko";
		} else if (Ext.isSafari && Ext.isAppleSafari) {
			return "safari";
		} else if (Ext.isSafari && !Ext.isAppleSafari) {
			return "chrome";
		} else {
			return "other";
		}
	},

	getProfileWindowSize: function() {
		var isSafari = Terrasoft.getBrowser().browserName.toLowerCase() == 'safari';
		if (Ext.isIE) {
			var windowToolbarWidth = window.startWidth - window.startInnerWidth;
			var windowToolbarHeight = window.startHeight - window.startInnerHeight;
			if (!windowToolbarWidth || windowToolbarWidth < 0) {
				windowToolbarWidth = 0;
			}
			if (!windowToolbarHeight || windowToolbarHeight < 0) {
				windowToolbarHeight = 0;
			}
			return {
				width: windowToolbarWidth + window.document.body.offsetWidth,
				height: windowToolbarHeight + window.document.body.offsetHeight
			};
		} else if (isSafari) {
			return {
				width: window.outerWidth,
				height: window.outerHeight
			};
		} else {
			return {
				width: window.innerWidth,
				height: window.innerHeight
			};
		}
	},

	getWindowParams: function(windowProfileUId, customWindowId) {
		var buf = [];
		buf.push("windowUId=", windowProfileUId, '&');
		buf.push("browserString=", customWindowId + this.getProfileBrowserString());
		return buf.join("");
	},

	getParams: function() {
		var buf = [];
		buf.push("profileId=", this.profileId, '&');
		buf.push("key=", this.key, '&');
		buf.push("profileDataSource=", encodeURIComponent(Ext.util.JSON.encodeObject(this.data)), '&');
		if (window.windowProfileUId) {
			var windowSize = this.getProfileWindowSize();
			if (window.opener && window.opener.profileData && windowSize.width && windowSize.height) {
				window.opener.profileData.setCachedWindowSize(window.windowProfileUId, window.customWindowId, windowSize.width, windowSize.height);
			}
			buf.push("windowProfile=", Ext.util.JSON.encodeObject({
				windowProfileUId: window.windowProfileUId,
				width: windowSize.width,
				height: windowSize.height,
				browserString: window.customWindowId + this.getProfileBrowserString()
			}), "&");
		} else {
			buf.push("windowProfile=", "&");
		}
		var logout = "false";
		if (window.logout === true) {
			logout = "true";
			window.logout = false;
		}
		buf.push("doLogout=", logout, '&');
		var customDataFieldEl = Ext.get('customDataField');
		var customDataValue = '';
		if (customDataFieldEl) {
			customDataValue = Ext.decode(customDataFieldEl.dom.value);
			customDataValue.dataSourceCacheItemNames = Terrasoft.EntityDataSourceMgr.getDataSourceCacheItemNames();
		}
		buf.push("customData=", Ext.encode(customDataValue));
		return buf.join("");
	},

	handleResponse: function (response) {
		var xmlData = response.responseXML;
		var root = xmlData.documentElement || xmlData;
		var data = root.text || root.textContent;
		var result = eval(data);
		if (result) {
			this.clearProfileData();
		}
	},

	handleFailure: function (response) {
	},

	clearProfileData: function () {
		this.data = new Object();
	}

};

Terrasoft.HelpContext = function() {
	var getItemHelpContextConfig = function (item) {
		if (!item) {
			return null;
		}
		if (item.helpContextId) {
			return {
				helpContextId: item.helpContextId,
				lmsUrl: Terrasoft.lmsUrl,
				product: item.productEdition,
				configurationVersion: Terrasoft.configurationVersion
			};
		}
		return getItemHelpContextConfig(item.ownerCt);
	};

	var getSysHelpSettings = function(callback, scope) {
		var sysHelpSettings = {};
		Terrasoft.SystemSettings.getValue("UseLMSDocumentation", function(code, value) {
			sysHelpSettings[code] = value;
			Terrasoft.SystemSettings.getValue("ProductEdition", function(code, value) {
				sysHelpSettings[code] = value;
				callback.call(scope, sysHelpSettings);
			});
		});
	};

	var show = function (helpContextId, controlId, helpUrl) {
		var callback = function(sysHelpSettings) {
			var isUseLMSDocumentation = sysHelpSettings.UseLMSDocumentation === "true";
		var control = Ext.getCmp(controlId);
		var helpContextConfig = getItemHelpContextConfig(control) || helpContextId;
		var windowUrl;
			if (helpUrl && isUseLMSDocumentation) {
			windowUrl = helpUrl;
		} else {
				if (helpContextConfig && isUseLMSDocumentation) {
					windowUrl = getLmsDocumentationUrl(helpContextConfig);
			} else {
					windowUrl = getHelpUrl(helpContextId, sysHelpSettings.ProductEdition);
			}
		}
			window.open(windowUrl, "_blank");
		};
		getSysHelpSettings(callback, this);
	};

	var showVideo = function(videoHelpCode) {
		var stringList = Ext.StringList('WC.Common');
		var windowCaption = stringList.getValue('VideoHelp.WindowCaption');
		var moduleInfoWindow = new Terrasoft.Window({
			id: 'videoHelpWindow',
			name: 'moduleInfoWindow',
			caption: windowCaption,
			resizable: false,
			width: 800,
			frame: true,
			height: 600,
			modal: true,
			frameStyle: 'padding: 0 0 0 0'
		});
		var videoLayout = new Terrasoft.ControlLayout({
			id: moduleInfoWindow.id + '_videoLayout',
			direction: 'horizontal',
			width: '100%',
			height: '100%'
		});
		var htmlPageContainer = new Terrasoft.HtmlPageContainer({
			id: moduleInfoWindow.id + '_htmlPageContainer',
			direction: 'horizontal',
			width: '100%',
			height: '100%'
		});
		htmlPageContainer.setSourceUrl(videoHelpCode);
		videoLayout.add(htmlPageContainer);
		moduleInfoWindow.add(videoLayout);
		moduleInfoWindow.show();
	};

	function getLmsDocumentationUrl(config) {
		var path = config.lmsUrl;
		var parameters = [];
		var product = config.product;
		if (product) {
			parameters.push("product=" + encodeURIComponent(product));
		}
		var configurationVersion = config.configurationVersion;
		if (configurationVersion) {
			parameters.push("ver=" + encodeURIComponent(configurationVersion));
		}
		var helpContextId = config.helpContextId;
		if (helpContextId) {
			parameters.push("id=" + encodeURIComponent(helpContextId));
		}
		return path + "?" + parameters.join("&");
	}

	function getHelpUrl(helpContextId, productEdition) {
		var helpDirectory = "/WebHelp";
		var cultureName = Terrasoft.CultureInfo.name;
		var helpMainPage = "BPMonline_Help.htm";
		var productEditionUrl = Ext.isEmpty(productEdition) ? "" : "/" + productEdition;
		var workspaceBaseUrl = document.location.origin + Terrasoft.applicationPath;
		var helpUrl = workspaceBaseUrl + helpDirectory + productEditionUrl + "/" +
			cultureName.substring(0, 2) + "/" + helpMainPage;
		if (helpContextId && helpContextId !== "null") {
			var separator = "/";
			var arr = helpContextId.split(separator);
			if (arr.length > 1) {
				var prefix = arr[0];
				helpContextId = arr[1];
				helpDirectory += prefix;
				helpUrl = helpDirectory + "/" + helpMainPage;
			}
			helpUrl += "#<id=" + helpContextId;
		}
		return helpUrl;
	}

	return {
		showHelp: function(helpContextId, controlId, helpUrl) {
			show(helpContextId, controlId, helpUrl);
		},

		showVideoHelp: function(videoHelpCode) {
			showVideo(videoHelpCode);
		},

		showHelpOnKeyDown: function(e) {
			if (((e.getKey() == e.H || e.getKey() == 104) && e.altKey === true)) {
				show(null, null);
			}
		}
	};
} ();

Terrasoft.FocusManager = function() {
	
	var focusedControl = undefined;

	return {
		setFocusedControl: function(control) {
			if (control.isInnerControl === true || focusedControl == control) {
				return;
			}
			if (control.canFocus === false) {
				if (focusedControl) {
					focusedControl.focus();
				}
				return;
			}
			if (focusedControl && focusedControl.hasFocus !== false) {
				focusedControl.unFocus();
			}
			focusedControl = control;
		},

		getFocusedControl: function() {
			return focusedControl;
		},

		fixFocus: function() {
			if (focusedControl) {
				focusedControl.focus();
			}
		}
	};
} ();

Terrasoft.QueueManager = function() {

	var queues = {};

	function Queue(config) {
		this.queueName = config.queueName;
		this.execteCallback = config.execteCallback;
		this.executeScope = config.executeScope;
	}

	Queue.prototype = {
		queueName: '',
		execteCallback: null,
		executeScope: null,
		executing: false,
		handlers: [],

		addHandler: function(method, scope, args) {
			this.handlers.push({
				method: method,
				scope: scope || window,
				args: args
			});
		},

		getHandlersCount: function() {
			return this.handlers.length;
		},

		execute: function() {
			if (this.executing === true) {
				return;
			}
			this.executing = true;
			var handler = this.handlers.shift();
			var handlerArgs = handler.args;
			var args = [];
			for (var i = 0; i < handlerArgs.length; i++) {
				args[i] = handlerArgs[i];
			}
			function onExecuted() {
				this.executing = false;
				if (this.getHandlersCount() != 0) {
					this.execute();
				}
			};
			args.push(onExecuted);
			args.push(this);
			handler.method.apply(handler.scope, args);
		}
	};

	return {
		EnqueueExecution: function(method, scope, queueName, args) {
			var queue = queues[queueName];
			if (!queue) {
				queue = queues[queueName] = new Queue({
					queueName: queueName
				});
			}
			queue.addHandler(method, scope, args);
			queue.execute();
		}
	};
}();

Terrasoft.redirect = function(url) {
	window.location.replace(url);
};

Terrasoft.Math = function () {
	var showTrailingZerosDef = true;
	var showThousandsDef = true;

	return {
		getDisplayValue: function(value, options) {
			options = options || {};
			var decimalSeparator = options.decimalSeparator || Terrasoft.CultureInfo.decimalSeparator;
			var decimalPrecision = options.decimalPrecision === undefined ?
				Terrasoft.CultureInfo.decimalPrecision : options.decimalPrecision;
			var showTrailingZeros =
				options.showTrailingZeros === undefined ? showTrailingZerosDef : options.showTrailingZeros;
			var showThousands = options.showThousands === undefined ? showThousandsDef : options.showThousands;
			var fixedValue = window.String(this.fixPrecision(value, decimalPrecision).toFixed(decimalPrecision));
			fixedValue = decimalSeparator === '.' ? fixedValue : fixedValue.replace(".", decimalSeparator);
			if (!showTrailingZeros) {
				fixedValue = this.fixTrailingZeros(fixedValue);
			}
			if (showThousands) {
				fixedValue = this.separateThousands(fixedValue);
			}
			return fixedValue;
		},

		parseValue: function(value) {
			value = window.parseFloat(window.String(value).replace(Terrasoft.CultureInfo.decimalSeparator, "."));
			return window.isNaN(value) ? '' : value;
		},

		fixPrecision: function(value, decimalPrecision) {
			value = window.String(value).replace(Terrasoft.CultureInfo.decimalSeparator, '.');
			if (window.isNaN(value) || Ext.isEmpty(value)) {
				if (this.allowEmpty) {
					return '';
				}
				value = '0';
			}
			var precision = decimalPrecision || Terrasoft.CultureInfo.decimalPrecision;
			if (precision == -1) {
				return value;
			}
			return window.parseFloat(window.parseFloat(value).toFixed(precision));
		},

		separateThousands: function(value, decimalSeparator, thousandSeparator) {
			var thousandSeparatorSymbol = thousandSeparator || Terrasoft.CultureInfo.numberGroupSeparator;
			var decimalSeparatorSymbol = decimalSeparator || Terrasoft.CultureInfo.decimalSeparator;
			var number = this.parseValue(value);
			var decimalSeparatorIndex = value.indexOf(decimalSeparatorSymbol);
			var presition = decimalSeparatorIndex >= 0 ? value.substring(decimalSeparatorIndex) : '';
			var isNegative = number < 0 ? "-" : "";
			var base = window.String(Math.floor(Math.abs(number)));
			var mod = base.length > 3 ? base.length % 3 : 0;
			var fixedValue = isNegative + (mod ? base.substring(0, mod) + thousandSeparatorSymbol : "");
			fixedValue += base.substr(mod).replace( /(\d{3})(?=\d)/g , "$1" + thousandSeparatorSymbol);
			fixedValue += presition;
			return fixedValue;
		},

		fixTrailingZeros: function(value) {
			var decimalSeparator = Terrasoft.CultureInfo.decimalSeparator;
			var fixedValue = value.replace( /0*$/ , '');
			if (fixedValue.indexOf(decimalSeparator) == fixedValue.length - 1) {
				fixedValue = fixedValue.replace(decimalSeparator, '');
			}
			return fixedValue;
		}

	};
}();

Terrasoft.MIN_VALUE = -69999999999999.99;
Terrasoft.MAX_VALUE = 69999999999999.99;
Terrasoft.GUID_EMPTY = '00000000-0000-0000-0000-000000000000';

if (typeof Sys !== "undefined") {
	Sys.Application.notifyScriptLoaded();
}

Terrasoft.CultureInfo = {
	decimalSeparator: '.',
	numberGroupSeparator: ' ',
	decimalPrecision: 2,
	dateFormat: 'd.m.Y',
	timeFormat: 'G:i'
};

Terrasoft.WorkspaceFeatures = function() {
	return {
		hasFeature: function() {
			return false;
		}
	};
}();

Terrasoft.DataValueTypeManager = function () {
	var items = [];
	return {
		getById: function(id) {
			for (var i = 0, len = items.length; i < len; i++) {
				if (items[i].id == id) {
					return items[i];
				}
			}
			return null;
		},

		getByName: function(name) {
			for (var i = 0, len = items.length; i < len; i++) {
				if (items[i].name == name) {
					return items[i];
				}
			}
			return null;
		},

		loadData: function (dataArray) {
			items = dataArray;
		}
	};
} ();
