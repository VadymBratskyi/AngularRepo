Terrasoft.SilverlightContainer = Ext.extend(Ext.LayoutControl, {
	height: 300,
	width: 300,
	scriptableObjectName: "SilverlightApp",
	source: '',
	aceEditWrap: null,

	initComponent: function () {
		Terrasoft.SilverlightContainer.superclass.initComponent.call(this);
		this.parameters = this.parameters || {};
		if (!this.parameters.source) {
			this.parameters.source = '';
		}
		this.addEvents(
			'onpluginloaded',
			'onpluginsourcedownloadcomplete',
			'onpluginresized',
			'ondisposing',
			'oncustomevent'
		);
	},

	onRender: function (ct, position) {
		Terrasoft.SilverlightContainer.superclass.onRender.apply(this, arguments);
		var renderTo = this.renderTo || ct.id;
		renderTo = renderTo + "_Content" + this.id;
		this.el = ct.createChild({ id: renderTo });
		this.el.addClass('x-unselectable');
		this.parameters.parent = this;
		var id = this.id + "Component";
		var parametersSource = this.parameters.source;
		if (parametersSource != '') {
			parametersSource = Terrasoft.applicationPath + parametersSource;
		}
		parametersSource = String.format(parametersSource, window.location.host);
		var syntaxMemoRe = /Terrasoft\.UI\.WindowsControls\.SyntaxMemo\.xap$/;
		if (syntaxMemoRe.test(parametersSource)) {
			var aceEditWrap = this.aceEditWrap = new Terrasoft.AceEditWrap({
				ownerCt: this
			});
			aceEditWrap.on("aceinitialized", this.onAceInitialized, this);
			aceEditWrap.render(this.el);
		} else {
			Silverlight.__cleanup = Silverlight.__cleanup.createSequence(this.onContentDisposing, this);
			Silverlight.createObjectEx({
				source: parametersSource,
				parentElement: document.getElementById(renderTo),
				id: id,
				properties: {
					isWindowless: "True",
					enableHtmlAccess: "True",
					version: "4.0.60831.0"
				},
				events: {
					onLoad: this.onContentPluginLoaded.createDelegate(this),
					onResize: this.onContentPluginResized.createDelegate(this),
					OnSourceDownloadComplete: this.onContentPluginSourceDownloadComplete.createDelegate(this)
				}
			});
			Ext.getDoc().on('mouseup', this.onMouseUp, this);
		}
	},

	onMouseUp: function () {
		if (this.isPluginLoaded()) {
			this.scriptableObject.OnWindowMouseUp();
		}
	},

	onAceInitialized: function() {
		var aceEditWrap = this.scriptableObject = this.aceEditWrap;
		var scriptableEvents = this.scriptableEvents;
		if (scriptableEvents) {
			for (var i = 0, len = scriptableEvents.length; i < len; i++) {
				var eventName = scriptableEvents[i];
				aceEditWrap.on(eventName, this.aceEditEventHandler, this);
			}
		}
		this.fireEvent("onpluginloaded");
	},

	aceEditEventHandler: function(sender, args) {
		this.fireEvent("oncustomevent", sender, args);
	},

	on: function(eventName) {
		Terrasoft.SilverlightContainer.superclass.on.apply(this, arguments);
		if (eventName === "onpluginloaded" && this.aceEditWrap && this.scriptableObject) {
			this.fireEvent("onpluginloaded");
		}
	},

	onContentPluginLoaded: function (sender, args) {
		var parent = sender._parent = this;
		if (parent.scriptableObjectName) {
			var componentId = parent.id + "Component";
			var silverlightObject = this.silverlightObject = document.getElementById(componentId);
			var silverlightComponent = silverlightObject.content;
			var scriptableEvents = parent.scriptableEvents;
			var silverlightScriptableObject = silverlightComponent[parent.scriptableObjectName];
			this.content = silverlightComponent;
			if (silverlightScriptableObject != undefined) {
				silverlightScriptableObject.ClientId = componentId;
			}
			if (scriptableEvents) {
				for (var i = 0, len = scriptableEvents.length; i < len; i++) {
					var customEventFunction = function (sender, args) {
						var parent = document.getElementById(this.silverlightComponentId ||
							componentId)._parent;
						parent.fireEvent("oncustomevent", sender, args);
					};
					var eventName = scriptableEvents[i];
					customEventFunction.silverlightComponentId = componentId;
					silverlightScriptableObject[eventName] = customEventFunction;
				}
			}
			parent.scriptableObject = silverlightScriptableObject;
		}
		parent.fireEvent("onpluginloaded", sender, args);
	},

	isPluginLoaded: function () {
		if (this.aceEditWrap && this.scriptableObject) {
			return true;
		}
		var silverlightObject = this.silverlightObject;
		return silverlightObject !== undefined && this.silverlightObject.isLoaded === true && 
			(Ext.isIE ? this.isVisible(true) : true);
	},

	isVisible: function (deep) {
		return this.rendered && this.getActionEl().isVisible(deep);
	},
	
	onResize: function () {
		Terrasoft.SilverlightContainer.superclass.onResize.apply(this, arguments);
		var scriptableObjectEl = this.el.child('object');
		if (scriptableObjectEl) {
			scriptableObjectEl.setWidth(this.width);
			scriptableObjectEl.setHeight(this.height);
		}
	},

	onContentDisposing: function (sender, args) {
		this.fireEvent("ondisposing", sender, args);
	},

	onContentPluginResized: function (sender, args) {
		this.fireEvent("onpluginresized", sender, args);
	},

	onContentPluginSourceDownloadComplete: function (sender, args) {
		this.fireEvent("onpluginsourcedownloadcomplete", sender, args);
	}

});

Ext.reg('silverlightcontainer', Terrasoft.SilverlightContainer);

if (typeof Sys !== "undefined") { Sys.Application.notifyScriptLoaded(); }