/* jshint ignore:start */
Ext.Button = Ext.extend(Ext.LayoutControl, {
	autoWidth: true,
	spriteXOffset:0,
	spriteYOffset:0,
	imageAsSprite: true,
	hidden: false,
	imagePosition: "Left",
	width: 75,
	defaultToolBtnWithMenuWidth: 40,
	defaultToolBtnWidth: 25,
	enabled: true,
	clickEvent: "click",
	handleMouseEvents: true,
	buttonLeftSideSelector: "td:nth-child(1)",
	buttonCenterSelector: "td:nth-child(2)",
	buttonRightSideSelector: "td:nth-child(3)",
	buttonSelector: "table:first",
	imageSelector: ".x-ico",
	menuAlign: "tl-bl?",
	defaultButton: false,
	arrowButtonWidth: 15,
	buttonStyle : "blue",
	pressed: false,
	toggleGroup: "",
	allowDepress: false,
	pressedCls: "x-btns-pressed",
	pressedArrowCls: "x-btns-arrow-pressed",
	disabledClass: "x-item-disabled",

	initComponent: function() {
		Ext.Button.superclass.initComponent.call(this);
		this.addEvents(
			"click",
			"toggle",
			"mouseover",
			"mouseout",
			"menushow",
			"menuhide",
			"menutriggerover",
			"menutriggerout",
			"arrowclick",
			"menuitemclick"
		);
		if (this.menuConfig && this.menuConfig.length > 0) {
			this.ensureMenuCreated();
			this.menu.createItemsFromConfig(this.menuConfig);
		}
	},

	onMenuElementChange: function() {
		var visibleItems = this.menu.getVisibleItems();
		var hasMenu = this.el.button.hasClass("x-btns-with-menu");
		if (visibleItems.length <= 0 && hasMenu) {
			this.hideButtonMenu();
		} else if (visibleItems.length > 0 && !hasMenu) {
			this.showButtonMenu();
		}
	},

	addMenuItemsEvents: function() {
		var items = this.menu.items;
		for (var i = 0, length = items.length; i < length; i++) {
			var item = items.itemAt(i);
			item.on({
				hide: this.onMenuElementChange,
				show: this.onMenuElementChange,
				add: this.onMenuElementChange,
				remove: this.onMenuElementChange,
				scope: this
			});
		}
	},

	ensureMenuCreated: function() {
		if (!this.menu) {
			this.menu = new Ext.menu.Menu({
				id: Ext.id(),
				markerValue: this.id
			});
			this.menu.owner = this;
			this.menu.on("show", this.onMenuShow, this);
		}
	},

	getMenu: function() {
		this.ensureMenuCreated();
		return this.menu;
	},

	setImageAsSprite: function(imageAsSprite) {
		this.imageAsSprite = imageAsSprite;
		if (!this.rendered) {
			return;
		}
		if (imageAsSprite) {
			this.el.button.removeClass("nosprite");
		} else {
			if (!this.el.button.hasClass("nosprite")) {
				this.el.button.addClass("nosprite");
			}
		}
	},

	setButtonStyle: function(buttonStyle) {
		var oldButtonStyle = this.buttonStyle;
		this.buttonStyle = buttonStyle.toLowerCase();
		if (!this.rendered) {
			return;
		}
		this.applyColorSchema(this.el, oldButtonStyle);
	},

	setAutowidth: function(autoWidth) {
		this.autoWidth = autoWidth;
		if (!this.el) {
			return;
		}
		this.setWidth(this.width);
	},

	insert: function(index, item) {	
		this.ensureMenuCreated();
		item.rendered = false;
		item.parentMenu = this.menu;
		return this.menu.insert(index, item);
	},

	moveControl: function(item, position) {
		item.parentMenu.remove(item, true);
		if (item.parentMenu.owner && item.parentMenu.owner.onContentChanged) {
			item.parentMenu.owner.onContentChanged();
		}
		this.insert(position, item);
		this.onContentChanged();
	},

	removeControl: function(item) {
		if (!this.menu) {
			return;
		}
		this.menu.remove(item);
		this.onContentChanged();
		return item;
	},

	add: function(item) {
		this.ensureMenuCreated();
		item.parentMenu = this.menu;
		return this.menu.add(item);
	},

	onContentChanged: function() {
		if (!this.rendered) {
			return;
		}
		var rightSideButton = this.el.child(this.buttonRightSideSelector);
		if (this.menu && this.menu.items.items.length > 0) {
			var visibleItems = this.menu.getVisibleItems();
			if (visibleItems.length > 0) {
				this.el.arrowButton = this.arrowBtnEl = rightSideButton;
				this.initArrowButtonEl(this.el, rightSideButton);
				if (this.arrowTooltip) {
					rightSideButton.dom[this.tooltipType] = this.arrowTooltip;
				}
				this.showButtonMenu();
			}
		} else {
			delete this.el.arrowButton;
			this.hideButtonMenu();
		}
		if (this.menu && this.menu.items.items.length == 0) {
			this.menu.un("show", this.onMenuShow, this);
			Ext.destroy(this.menu);
			delete this.menu;
		}
		this.doAutoWidth();
		if (this.ownerCt) {
			this.ownerCt.fireEvent("contentchanged");
		}
	},

	hideButtonMenu: function() {
		var rightSideButton = this.el.child(this.buttonRightSideSelector);
		this.el.button.removeClass("x-btns-with-menu");
		rightSideButton.addClass("x-btns-r");
		rightSideButton.addClass("x-btns-r-" + this.buttonStyle);
		rightSideButton.removeClass("x-btns-menu-arrow");
		rightSideButton.removeClass("x-btns-menu-arrow-" + this.buttonStyle);
		this.doAutoWidth();
	},

	showButtonMenu: function() {
		var rightSideButton = this.el.child(this.buttonRightSideSelector);
		rightSideButton.removeClass("x-btns-r");
		rightSideButton.removeClass("x-btns-r-" + this.buttonStyle);
		rightSideButton.addClass("x-btns-menu-arrow");
		rightSideButton.addClass("x-btns-menu-arrow-" + this.buttonStyle);
		this.el.button.addClass("x-btns-with-menu");
	},

	applyColorSchema: function(btn, oldButtonStyle) {
		var buttonStyle = this.buttonStyle;
		if (!oldButtonStyle) {
			oldButtonStyle = Ext.Button.prototype.buttonStyle;
		}
		if (buttonStyle != oldButtonStyle) {
			btn.child(this.buttonCenterSelector).replaceClass("x-btns-" + oldButtonStyle, 
				"x-btns-" + buttonStyle);
			btn.child(this.buttonLeftSideSelector).replaceClass("x-btns-l-" + oldButtonStyle, 
				"x-btns-l-" + buttonStyle);
			this.arrowBtnEl ? btn.child(this.buttonRightSideSelector).replaceClass("x-btns-menu-arrow-" + oldButtonStyle, 
					"x-btns-menu-arrow-" + buttonStyle) :
				btn.child(this.buttonRightSideSelector).replaceClass("x-btns-r-" + oldButtonStyle, 
					"x-btns-r-" + buttonStyle);
		}
		if (Ext.isIE === true) {
			btn.child("button").setStyle("top", "-1px");
		}
		this.doAutoWidth();
	},

	getTemplate: function(isMenuButton) {
		var tpl;
		if (isMenuButton) {
			tpl = this.arrowBtnTpl;
			if (tpl) {
				return tpl;
			}
			Ext.Button.prototype.arrowBtnTpl = tpl =
					new Ext.Template('<table class="x-btns-table" cellpadding="0" cellspacing="0" border="0"><tbody>',
									 '<tr><td class="x-btns-l x-btns-l-blue"></td>',
									 '<td valign="middle" halign="center" class="x-btns x-btns-blue"><div class="x-btns-m"><div class="x-btns-content x-ico">',
									 '<button class="x-btns-text" type="button" hideFocus="hidefocus">{0}</button></div></div></td>',
									 '<td class="x-btns-menu-arrow x-btns-menu-arrow-blue"></td></tr></tbody></table>');
			} else {
			tpl = this.btnTpl;
			if (!tpl) {
				Ext.Button.prototype.btnTpl = tpl = new Ext.Template('<table class="x-btns-table"><tbody>',
									 '<tr><td class="x-btns-l x-btns-l-blue"></td>',
									 '<td valign="middle" halign="center" class="x-btns x-btns-blue"><div class="x-btns-m"><div class="x-btns-content x-ico">',
									 '<button class="x-btns-text" type="button" hideFocus="hidefocus">{0}</button></div></div></td>',
									 '<td class="x-btns-r x-btns-r-blue"></td></tr></tbody></table>');
			} else {
				return tpl;
			}
			}
		tpl.disableFormats = true;
		tpl.compile();
		return tpl;
	},

	onRender: function(ct, position) {
		var btnEl, arrBtnEl;
		var isMenuButton = !!this.menu;
		var tpl = this.getTemplate(isMenuButton);
		var btn, targs = [this.caption || "&#160;", Ext.BLANK_IMAGE_URL];
			if (position) {
			btn = tpl.insertBefore(position, targs, true);
			} else {
			btn = tpl.append(ct, targs, true);
			}
		if (isMenuButton) {
			this.arrowBtnEl = arrBtnEl = btn.child(this.buttonRightSideSelector);
		}
		
		btnEl = btn;
		Ext.ButtonToggleMgr.register(this);
		
		this.applyColorSchema(btn);
		btn.unselectable();
		
		this.buttonClickEl = btn.child("div");
		this.buttonEl = btn.child("button:first");
		if (!this.designMode) {
			this.buttonEl.on("focus", this.onFocus, this);
			this.buttonEl.on("blur", this.onBlur, this);
			this.buttonEl.on("keydown", this.onKeyDown, this);
		}
		this.buttonText = btn.child(this.buttonLeftSideSelector);
		this.initButtonEl(btn, btnEl);
		var menu = this.menu;
		if (menu) {
			this.initArrowButtonEl(btn, arrBtnEl);
			if (this.arrowTooltip) {
				btn.child(this.buttonRightSideSelector).dom[this.tooltipType] = this.arrowTooltip;
			}
			if (menu.items) {
				this.addMenuItemsEvents();
			}
		}
		this.el.image = btn.child(this.imageSelector);
		if (!this.imageAsSprite) {
			this.el.button.addClass("nosprite");
		}
		var imageSrc = this.getImageSrc();
		if (!Ext.isEmpty(imageSrc) && imageSrc != Ext.BLANK_IMAGE_URL) {
			this.el.image.setStyle("background-image", imageSrc);
			var spriteXOffset = this.spriteXOffset;
			var spriteYOffset = this.spriteYOffset;
			if (spriteXOffset != 0 || spriteYOffset != 0) {
				this.el.image.setStyle("background-position", spriteXOffset + "px " + spriteYOffset  +"px");
				
			}
			this.isImageVisible = true;
		} else {
			this.isImageVisible = false;
		}
		this.setDefaultButton(this.defaultButton);
		this.el.button.on("mousemove", this.onMouseMove, this);
		if (menu && menu.visibleItems && menu.visibleItems.length == 0) {
			this.hideButtonMenu();
		}
	},

	setImage: function(value) {
		this.imageConfig = value;
		var imageSrc = this.getImageSrc();
		var imageEl = this.el.image;
		if (!Ext.isEmpty(imageSrc) && imageSrc != Ext.BLANK_IMAGE_URL) {
			imageEl.setStyle("background-image", imageSrc);
			var spriteXOffset = this.spriteXOffset;
			var spriteYOffset = this.spriteYOffset;
			if (spriteXOffset != 0 || spriteYOffset != 0) {
				imageEl.setStyle("background-position", spriteXOffset + "px " + spriteYOffset  +"px");
			}
			this.isImageVisible = true;
		} else {
			this.isImageVisible = false;
		}
		this.doAutoWidth();
	},

	onKeyDown: function(e) {
		if (!this.enabled) {
			return;
		}
		e = (e) ? e : window.event;
		if(e) {
 			var elm = (e.target) ?
 				e.target : e.srcElement;
 			if(elm) {
 				var code = (e.charCode)?
 					e.charCode : e.keyCode;
 				if(code == 32) {
					e.button = 0;
					this.onClick(e);
 					return false;
				} else {
					return true;
				}
 			}
		}
	},

	beforeDestroy: function() {
		if (this.rendered) {
			var btn = this.el.button;
			if (btn) {
				btn.removeAllListeners();
			}
			if (!this.designMode) {
				this.buttonEl.un("focus", this.onFocus, this);
				this.buttonEl.un("blur", this.onBlur, this);
				this.buttonEl.un("keydown", this.onKeyDown, this);
			}
		}
		Terrasoft.Button.superclass.beforeDestroy.call(this);
	},

	onDestroy: function() {
		if (this.menu) {
			this.menu.un("show", this.onMenuShow, this);
			Ext.destroy(this.menu);
		}
		if (this.rendered) {
			Ext.ButtonToggleMgr.unregister(this);
			Ext.destroy(this.el.button);
		}
		Terrasoft.Button.superclass.onDestroy.call(this);
	},

	onDisable: function() {
		var el = this.el;
		if (this.menu && el && el.arrowButton) {
			el.arrowButton.addClass(this.disabledClass);
		}
		if (el) {
			var buttonEl = el.button;
			if (buttonEl) {
				buttonEl.dom.setAttribute("disabled","disabled");
				el.addClass(this.disabledClass);
			}
		}
		this.enabled = false;
	},

	onEnable: function() {
		var el = this.el;
		if (this.menu && el && el.arrowButton) {
			el.arrowButton.removeClass(this.disabledClass);
		}
		if (el) {
			var buttonEl = el.button;
			if (buttonEl) {
				buttonEl.dom.removeAttribute("disabled");
				el.removeClass(this.disabledClass);
			}
		}
		this.enabled = true;
	},

	onClick: function(e) {
		var menu = this.menu;
		if (!Ext.isEmpty(menu || e)) {
			e.preventDefault();
		}
		if (menu) {
			if (this.enabled) {
				if (this.hasListener("click")) {
					this.fireEvent("click", this, e);
				} else if (menu.items) {
					var visibleItems = menu.getVisibleItems();
					if (visibleItems.length > 0) {
						this.showMenu(e);
					}
				}
			}
			if (this.handler) {
				this.handler.call(this.scope || this, this, e);
			}
		} else {
			if (e.button != 0) {
				return;
			}
			if (this.enabled) {
				if (this.processToggle(e)) {
					this.buttonEl.dom.focus();
					if (this.handler) {
						this.handler.call(this.scope || this, this, e);
					}
					if (this.closeResult) {
						var parentWindow = this.findParentWindow();
						if (parentWindow) {
							parentWindow.close(this.closeResult);
						}
					}
				}
			}
		}
	},
	
	findParentWindow: function() {
		var parent = this.ownerCt;
		while (parent) {
			if (parent instanceof Terrasoft.Window) {
				return parent;
			}
			parent = parent.ownerCt;
		}
		return null;
	},

	processToggle: function(e) {
		var needFireClickEvent;
		if (this.toggleGroup != "") {
			if (this.allowDepress !== false || !this.pressed) {
				needFireClickEvent = true;
				this.toggle();
			} else {
				needFireClickEvent = false;
			}
		}
		if (needFireClickEvent !== false) {
			this.fireEvent("click", this, e);
			return true;
		}
		return false;
	},

	setImagePosition: function(imagePosition) {
		this.imagePosition = imagePosition;
		this.doAutoWidth();
	},

	setToggleGroup: function(toggleGroup) {
		if (this.toggleGroup != toggleGroup) {
			if (this.rendered) {
				this.processToggle();
			}
			this.toggleGroup = toggleGroup;
			if (this.rendered) {
				this.processToggle();
			}
		}
	},

	applyPressedState: function(state) {
		var arrowBtnEl = this.arrowBtnEl;
		if (state) {
			if (!this.el.button.hasClass(this.pressedCls)) {
				this.el.button.addClass(this.pressedCls);
			}
			if (arrowBtnEl) {
				if (!arrowBtnEl.hasClass(this.pressedArrowCls)) {
					arrowBtnEl.addClass(this.pressedArrowCls);
				}
			}
			this.pressed = true;
		} else {
			this.el.button.removeClass(this.pressedCls);
			if (arrowBtnEl) {
				arrowBtnEl.removeClass(this.pressedArrowCls);
			}
			this.pressed = false;
		}
	},

	setPressed: function(pressed) {
		this.processToggle();
		this.pressed = pressed;
		if (!this.rendered) {
			return;
		}
		this.applyPressedState(pressed);
	},

	setAllowDepress: function(allowDepress) {
		this.allowDepress = allowDepress;
		if (!this.rendered) {
			return;
		}
		this.applyPressedState(this.pressed);
	},

	toggle: function(state) {
		var pressed = this.pressed;
		var state = (state === undefined) ? !pressed : state;
		if (state != pressed) {
			this.applyPressedState(state);
			if (state) {
				this.fireEvent("toggle", this, true);
			} else {
				this.fireEvent("toggle", this, false);
			}
			if (this.toggleHandler) {
				this.toggleHandler.call(this.scope || this, this, state);
			}
		}
	},

	isMenuTriggerOver: function(e, internal) {
		if (this.menu && this.arrowBtnEl) {
			return this.menu && e.within(this.arrowBtnEl) && !e.within(this.arrowBtnEl, true);
		}
		return this.menu && !internal;
	},

	isMenuTriggerOut: function(e, internal) {
		if (this.menu && this.arrowBtnEl) {
			return this.menu && !e.within(this.arrowBtnEl);
		}
		return this.menu && !internal;
	},

	onMouseDown: function(e) {
		if (this.enabled && e.button == 0) {
			var btn = this.el.button;
			var internal = this.arrowBtnEl ? e.withinExt(this.arrowBtnEl) : false;
			if (internal) {
				btn.addClass("x-btns-arrow-click");
				if (!this.hasListener("click")) {
					btn.addClass("x-btns-click");
					if (this.imageAsSprite) {
						this.el.image.addClass("x-btns-img-click");
					}
				}
			} else {
				 if (!this.hasListener("click")) {
					btn.addClass("x-btns-arrow-click");
				 }
				 btn.addClass("x-btns-click");
				 if (this.imageAsSprite) {
					this.el.image.addClass("x-btns-img-click");
				}
			}
			if (Ext.isAppleSafari) {
				btn.child(".x-btns").setStyle("text-indent", "-1px");
			}
			Ext.getDoc().on("mouseup", this.onMouseUp, this);
		}
	},

	onMouseUp: function(e) {
		if (e.button == 0) {
			Ext.getDoc().un("mouseup", this.onMouseUp, this);
			var btn = this.el.button;
			btn.removeClass("x-btns-arrow-click");
			btn.removeClass("x-btns-click");
			this.el.image.removeClass("x-btns-img-click");
			var internal = e.within(btn);
			if (internal == true) {
				if (!this.hasListener("click")) {
					this.onClick(e);
				} else {
					var internalArrow = this.arrowBtnEl ? e.withinExt(this.arrowBtnEl) : false;
					if (!internalArrow) {
						this.onClick(e);
					}
				}
			}
		}
	},

	onMouseOver: function(e) {
		if (this.enabled) {
			var internal = e.within(this.el.button, true);
			if (!internal) {
				if (!this.monitoringMouseOver) {
					Ext.getDoc().on("mouseover", this.monitorMouseOver, this);
					this.monitoringMouseOver = true;
				}
				this.fireEvent("mouseover", this, e);
				if (this.isMenuTriggerOver(e, internal)) {
					this.fireEvent("menutriggerover", this, this.menu, e);
				}
				var internalArrow = this.arrowBtnEl ?
					e.withinExt(this.arrowBtnEl) || e.withinExt(this.arrowBtnEl, true) : false;
				if (internalArrow) {
					this.el.button.addClass("x-btns-arrow-over");
					if (!this.hasListener("click")) {
						this.el.button.addClass("x-btns-over");
						if (this.imageAsSprite) {
							this.el.image.addClass("x-btns-img-over");
						}
					} else {
						this.el.button.removeClass("x-btns-over");
						if (this.imageAsSprite) {
							this.el.image.removeClass("x-btns-img-over");
						}
					}
				} else {
					 if (!this.hasListener("click")) {
						this.el.button.addClass("x-btns-arrow-over");
					 } else { 
						this.el.button.removeClass("x-btns-arrow-over");
					 }
					 this.el.button.addClass("x-btns-over");
					 if (this.imageAsSprite) {
						this.el.image.addClass("x-btns-img-over");
					}
				}
			}
		}
	},

	monitorMouseOver: function(e) {
		var internalArrow = this.arrowBtnEl ?
			e.withinExt(this.arrowBtnEl) || e.withinExt(this.arrowBtnEl, true) : false;
		if (internalArrow) {
			if (this.hasListener("click")) {
				if (!this.el.button.hasClass("x-btns-arrow-over")) {
					this.el.button.addClass("x-btns-arrow-over");
					this.el.button.removeClass("x-btns-over");
					this.el.image.removeClass("x-btns-img-over");
				}
			}
		} else {
			if (this.hasListener("click")) {
				if (this.el.button.hasClass("x-btns-arrow-over")) {
					this.el.button.removeClass("x-btns-arrow-over");
					this.el.button.addClass("x-btns-over");
					if (this.imageAsSprite) {
						this.el.image.addClass("x-btns-img-over");
					}
				}
			}
		}
		if (e.target != this.el.button.dom && !e.within(this.el.button)) {
			this.el.button.removeClass("x-btns-click");
			this.el.image.removeClass("x-btns-img-click");
			this.el.button.removeClass("x-btns-arrow-click");
			if (this.monitoringMouseOver) {
				Ext.getDoc().un("mouseover", this.monitorMouseOver, this);
				this.monitoringMouseOver = false;
			}
			this.onMouseOut(e);
		}
	},

	onMouseOut: function(e) {
		var internal = e.within(this.el.button) && e.target != this.el.button.dom;
		this.el.button.removeClass("x-btns-over");
		this.el.button.removeClass("x-btns-arrow-over");
		this.el.image.removeClass("x-btns-img-over");
		this.fireEvent("mouseout", this, e);
		if (this.isMenuTriggerOut(e, internal)) {
			this.fireEvent("menutriggerout", this, this.menu, e);
		}
	},

	onFocus: function(e) {
		if (this.enabled) {
			this.hasFocus = true;
			Terrasoft.FocusManager.setFocusedControl.defer(10, this, [this]);
			var clickEl = this.buttonClickEl;
			if (!clickEl.hasClass("x-btns-focus")) {
				clickEl.addClass("x-btns-focus");
				var isTextEmpty = Ext.isEmpty(this.caption);
				var isImageVisible = this.isImageVisible;
				if (isImageVisible && !isTextEmpty) {
					if ((Ext.isSafari || Ext.isIE) && !Ext.isAppleSafari) {
						this.el.image.setStyle("margin-left", "1px");
						this.buttonEl.setStyle("padding-left", "19px");
					}
				}
				if (Ext.isGecko || Ext.isAppleSafari) {
					this.buttonEl.setStyle("margin-left", "-2px");
				}
			}
		}
	},

	onBlur: function(e) {
		this.triggerBlur();
	},

	unFocus: function() {
		this.triggerBlur();
	},

	triggerBlur: function() {
		this.hasFocus = false;
		this.buttonClickEl.removeClass("x-btns-focus");
		var isTextEmpty = Ext.isEmpty(this.caption);
		var isImageVisible = this.isImageVisible;
		if (isImageVisible && !isTextEmpty) {
			if ((Ext.isSafari || Ext.isIE) && !Ext.isAppleSafari) {
				this.el.image.setStyle("margin-left", "2px");
				this.buttonEl.setStyle("padding-left", "18px");
			}
		}
		if (Ext.isGecko || Ext.isAppleSafari) {
			this.buttonEl.setStyle("margin-left", "0px");
		}
	},

	onMouseMove: function(e) {
		if (e.button == 0) {
			e.preventDefault();
		}
	},

	onMenuShow: function(e) {
		this.ignoreNextClick = 0;
		this.fireEvent("menushow", this, this.menu);
	},

	onMenuHide: function(e) {
		this.el.removeClass("x-btn-menu-active");
		this.ignoreNextClick = this.restoreClick.defer(250, this);
		this.fireEvent("menuhide", this, this.menu);
	},

	initButtonEl: function(btn, btnEl) {
		this.el = this.wrap = btn;
		this.el.button = btnEl;
		if (this.designMode) {
			btnEl.addClass("x-btn-design");
		}
		if (this.tabIndex !== undefined) {
			btnEl.dom.tabIndex = this.tabIndex;
		}
		if (this.handleMouseEvents) {
			btnEl.on("mouseover", this.onMouseOver, this);
			if (!this.designMode) {
				btnEl.on("mousedown", this.onMouseDown, this);
			}
		}
		if (this.id) {
			this.el.dom.id = this.el.id = this.id;
		}
		if (this.repeat) {
			var repeater = new Ext.util.ClickRepeater(btn,
				typeof this.repeat == "object" ? this.repeat : {});
			repeater.on(this.clickEvent, this.onClick, this);
		}
		if (this.pressed) {
			this.el.button.addClass(this.pressedCls);
			if (this.arrowBtnEl) {
				this.arrowBtnEl.addClass(this.pressedArrowCls);
			}
		} else {
			if (this.el.button.hasClass(this.pressedCls)) {
				this.el.button.removeClass(this.pressedCls);
				if (this.arrowBtnEl) {
					this.arrowBtnEl.removeClass(this.pressedArrowCls);
				}
			}
		}
	},

	setDefaultButton: function(defaultButton) {
		var button = this.el.button;
		if (defaultButton) {
			button.addClass("x-btn-default");
		} else {
			button.removeClass("x-btn-default");
		}
		var arrowButton = this.el.arrowButton;
		if (!arrowButton) {
			return;
		}
		if (defaultButton) {
			arrowButton.addClass("x-btn-menu-arrow-default");
		} else {
			arrowButton.removeClass("x-btn-menu-arrow-default");
		}
	},

	doAutoWidth: function(width) {
		if (!this.el) {
			return;
		}
		var isOrangeStyle = this.buttonStyle == "orange";
		var button = this.el.button;
		var btnMiddleEl = button.child(".x-btns-m");
		var menu = this.menu;
		var autoWidth = this.autoWidth;
		if (autoWidth) {
			width = this.getWidth();
		}
		var arrowBtnWidth = menu && menu.items && menu.items.items.length > 0 ? this.arrowButtonWidth/*-2*/-4 : 0;
		var defaultWidth = this.width || Ext.Button.prototype.width;
		var isTextEmpty = Ext.isEmpty(this.caption);
		var isImageVisible = this.isImageVisible;
		var imageOffset = 0;
		var imageEl = this.el.image;
		imageEl.removeClass("x-btns-with-text");
		imageEl.removeClass("x-btns-without-text");
		if (Ext.isIE7) {
			this.buttonEl.setWidth(Ext.util.TextMetrics.measure(this.buttonEl, this.caption).width + (isImageVisible ? 4 : -4) + 
				(arrowBtnWidth > 0 ? arrowBtnWidth+(isImageVisible && !isTextEmpty ? 5 : -5) : (isImageVisible && !isTextEmpty ? 14 : 4)));
		}
		if (!isTextEmpty) {
			this.buttonEl.setStyle("margin", "0px");
			this.buttonEl.setStyle("padding", "0px");
			if (!Ext.isGecko) {
				imageEl.setStyle("margin", "0px");
			}
			imageEl.setStyle("padding", "0px");
		}
		if (isImageVisible && !isTextEmpty) {
			if (!button.hasClass("x-btns-with-img")) {
				button.addClass("x-btns-with-img");
			}
			this.imagePosition != "Left" ? button.addClass("x-btns-with-img-right") :
				button.removeClass("x-btns-with-img-right");
			if (this.imagePosition == "Left") { 
				imageEl.setStyle("margin-left", "2px");
				this.buttonEl.setStyle("padding-left", "18px");
			} else {
				imageEl.setStyle("margin-right", "2px");
				this.buttonEl.setStyle("padding-right", "18px");
			}
		} else {
			button.removeClass("x-btns-with-img");
		}
		var btnWidth = 0;
		if (arrowBtnWidth) {
			if (isTextEmpty) {
				imageEl.addClass("x-btns-without-text");
				/// btnWidth = btnWidth + (Ext.isGecko ? 1 : 3);
				btnMiddleEl.setStyle("margin-right", "1px");
			} else {
				imageEl.addClass("x-btns-with-text");
				this.buttonEl.setStyle("padding-right", "2px");
				/// btnWidth = btnWidth + (Ext.isGecko && isImageVisible ? -2 : 0);
				/// btnMiddleEl.setStyle("margin-right", "0px");
			}
		}
		/// var textWidth = this.buttonEl.getWidth()-1;
		if (Ext.isGecko) {
			btnWidth = btnWidth - 4;
		}
		if (Ext.isAppleSafari) {
			btnWidth = btnWidth - 6;
		}
		var textWidth = this.buttonEl.getWidth();
		btnWidth = btnWidth + 3*2 + textWidth + 4*2 + arrowBtnWidth;
		if (Ext.isAppleSafari && isImageVisible && !isTextEmpty) {
			btnWidth += 2;
		}
		if (isImageVisible && !isTextEmpty) {
			btnWidth = btnWidth + imageOffset;
		}
		/// if (!isImageVisible || !arrowBtnWidth) {
			/// btnWidth = btnWidth + (Ext.isGecko ? 1 : 3);
		/// }
		if (isImageVisible && isTextEmpty) {
			if (arrowBtnWidth) {
				btnWidth = this.defaultToolBtnWithMenuWidth;
			} else {
				btnWidth = this.defaultToolBtnWidth;
			}
		}
		if (isOrangeStyle) {
			btnWidth = btnWidth + 10;
			if (Ext.isGecko) {
				btnWidth = btnWidth + 2;
			}
		}
		if ((defaultWidth > btnWidth) && (!isTextEmpty || !isImageVisible)) {
			btnWidth = defaultWidth;
		}
		if (autoWidth) {
			imageEl.setStyle("width", "");
			imageEl.removeClass("x-btns-manual-width");
			button.setWidth(btnWidth);
		} else {
			if (imageEl.hasClass("x-btns-manual-width")) {
				imageEl.addClass("x-btns-manual-width");
			}
			imageEl.setStyle("width", "");
			button.setWidth(this.width);
			if (width < btnWidth) {
				btnWidth = width - 4*2;
				if (isOrangeStyle) {
					btnWidth = btnWidth - 10;
				}
				btnWidth = btnWidth - (arrowBtnWidth ? 16 : (isImageVisible ? 4 : 0));
				imageEl.setWidth(btnWidth);
			}
		}
	},
	
	setWidth: function(width) {
		this.doAutoWidth(width);
	},
	
	setSize: function(w, h) {
		w = this.processSizeUnit(w);
		if (typeof w == "object") {
			w = w.width;
		}
		if (w == undefined) {
			return;
		}
		this.setWidth(w);
	},
	
	getWidth: function() {
		return this.el.getWidth();
	},

	getHeight: function() {
		return this.el.getHeight();
	},

	setHandler: function(handler, scope) {
		this.handler = handler;
		this.scope = scope;
	},

	setCaption: function(caption) {
		this.caption = caption;
		if (!this.rendered) {
			return;
		}
		var textEl = this.el.button.child("button");
		if (textEl) {
			if (caption != "") {
				textEl.update(caption);
			} else {
				textEl.update("&nbsp;");
			}
		}
		var oldWidth = this.getWidth();
		this.doAutoWidth();
		var newWidth = this.getWidth();
		if (oldWidth == newWidth) {
			return;
		}
		var ownerCt = this.ownerCt;
		if (ownerCt && ownerCt.direction == "horizontal") {
			ownerCt.doLayout(false);
		}
	},

	getCaption: function() {
		return this.caption;
	},

	getFocusEl: function() {
		return this.buttonEl;
	},

	restoreClick: function() {
		this.ignoreNextClick = 0;
	},

	setArrowHandler: function(handler, scope) {
		if (this.menu) {
			this.arrowHandler = handler;
			this.scope = scope;
		}
	},

	initArrowButtonEl: function(btn, arrBtnEl) {
		btn.addClass("x-btns-with-menu");
		this.el.arrowButton = arrBtnEl;
		if (this.defaultButton) {
			arrBtnEl.addClass("x-btn-menu-arrow-default");
		}
		arrBtnEl.on("mousemove", this.onMouseMove, this);
		arrBtnEl.on("mouseover", this.onArrowButtonMouseOver, this);
		arrBtnEl.on("mousedown", this.onArrowButtonMouseDown, this);
		arrBtnEl.on(this.clickEvent, this.onArrowButtonClick, this);
	},

	showMenu: function(e) {
		if (this.menu && this.enabled && !this.menu.isVisible() && !this.ignoreNextClick) {
			this.menu.show(this.el.button, this.menuAlign);
		}
		this.fireEvent("arrowclick", this, e);
		if (this.arrowHandler) {
			this.arrowHandler.call(this.scope || this, this, e);
		}
		return this;
	},

	hideMenu: function() {
		if (this.menu) {
			this.menu.hide();
		}
		return this;
	},

	monitorArrowButtonMouseOver: function(e) {
		if (e.target != this.el.arrowButton.dom && !e.within(this.el.arrowButton)) {
			if (this.monitoringArrowButtonMouseOver) {
				Ext.getDoc().un("mouseover", this.monitorArrowButtonMouseOver, this);
				this.monitoringArrowButtonMouseOver = false;
			}
			this.onArrowButtonMouseOut(e);
		}
	},

	onArrowButtonClick: function(e) {
		e.preventDefault();
		this.showMenu(e);
	},

	onArrowButtonMouseOver: function(e) {
		if (this.enabled) {
			var internal = e.within(this.el.arrowButton, true);
			if (!internal) {
				this.el.arrowButton.addClass("x-btns-over");
				if (!this.monitoringArrowButtonMouseOver) {
					Ext.getDoc().on("mouseover", this.monitorArrowButtonMouseOver, this);
					this.monitoringArrowButtonMouseOver = true;
				}
				this.fireEvent("mouseover", this, e);
			}
			if (this.isMenuTriggerOver(e, internal)) {
				this.fireEvent("menutriggerover", this, this.menu, e);
			}
		}
	},

	onArrowButtonMouseOut: function(e) {
		var internal = e.within(this.el) && e.target != this.el.dom;
		this.el.arrowButton.removeClass("x-btns-over");
		this.fireEvent("mouseout", this, e);
		if (this.isMenuTriggerOut(e, internal)) {
			this.fireEvent("menutriggerout", this, this.menu, e);
		}
	},

	onArrowButtonMouseDown: function(e) {
		if (this.enabled && e.button == 0) {
			this.el.arrowButton.addClass("x-btns-click");
			Ext.getDoc().on("mouseup", this.onArrowButtonMouseUp, this);
		}
	},

	onArrowButtonMouseUp: function(e) {
		if (e.button == 0) {
			this.el.arrowButton.removeClass("x-btns-click");
			Ext.getDoc().un("mouseup", this.onArrowButtonMouseUp, this);
		}
	}

});

Ext.reg("button", Ext.Button);

Ext.MenuButton = Ext.Button;

Terrasoft.Button = Ext.Button;

Ext.reg("tsbutton", Terrasoft.Button);
/* jshint ignore:end */