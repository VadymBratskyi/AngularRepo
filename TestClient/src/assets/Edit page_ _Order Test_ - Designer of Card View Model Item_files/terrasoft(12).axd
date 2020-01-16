Terrasoft.HtmlEdit = Ext.extend(Ext.form.TextField, {
	width: 300,
	height: 100,
	edges: '0 0 0 0',
	toolbarVisible: true,
	btnImageNamePrefix: 'htmledit-toolbar-btn-',
	ckEditorResourceManagerName: 'Terrasoft.UI.WebControls',
	ckEditorResourceItemName: 'ckeditor.js',
	invalidClass: 'x-form-htmledit-wrap-invalid',
	ckEditorInvalidClass: 'terrasoft-htmledit-invalid',
	ckEditorDisableClass: 'terrasoft-htmledit-disabled',

	formatPainterButtonVisible: true,

	formatSelectionVisible: false,
	fontNameSelectionVisible: true,
	fontSizeSelectionVisible: true,

	fontStyleButtonsVisible: true,
	colorButtonsVisible: true,
	listButtonsVisible: true,
	alignmentButtonsVisible: true,
	imageButtonVisible: true,
	linkButtonVisible: true,

	spellTextButtonVisible: false,

	formatedTextButtonVisible: true,
	plainTextButtonVisible: true,
	sourceEditButtonVisible: false,

	spellMenuStringList: null,
	noWordVariantsCaption: '',
	editWordCaption: '',

	defaultLinkValue: 'http:/' + '/',
	fontFamilies: [
		['Arial'],
		['Courier New'],
		['Tahoma'],
		['Times New Roman'],
		['Verdana']
	],

	ckEditorInitialized: false,
	activated: false,

	mode: 'formatedTextEditMode',
	availableEditordModes: ['plainTextEditMode', 'formatedTextEditMode', 'sourceEditMode'],
	spellMode: false,
	plainTextEditMode: false,
	formatedTextEditMode: true,
	sourceEditMode: false,

	defaultAutoCreate: {
		tag: 'textarea',
		autocomplete: "off"
	},
	allowEmpty: true,
	ignoreDataSourceProperties: false,

	ckDocumentDefaultCssProperties: {
		fontFamily: "Arial, Helvetica, sans-serif",
		fontSize: "12px",
		color: "#222",
		backgroundColor: "#ffffff"
	},

	ckEditorConfig: {
		enterMode: 3, // CKEDITOR.ENTER_DIV
		forceEnterMode: true,
		pasteFromWordRemoveFontStyles: true,
		pasteFromWordRemoveStyles: true,
		defaultLanguage: 'ru',
		language: 'ru',
		autoUpdateElement: false,
		editorTitle: '',
		width: '100%',
		height: '100%',
		contentsCss:
			"body {" +
				"	font-family: #(fontFamily);" +
				"	font-size: #(fontSize);" +
				"	color: #(color);" +
				"	background-color: #(backgroundColor);" +
				"}\n" +
				".terrasoft-htmledit-invalid { background-color: #FEEEEB; }\n" +
				".terrasoft-htmledit-disabled { background-color: #EBEFF5; }\n" +
				"ol,ul,dl { padding-right:40px; }\n" +
				"p { margin: 0px 0px 0px 0px !important; }\n",
		theme: 'TerrasoftTheme',
		skin: 'TerrasoftSkin',
		coreStyles_bold: {
			element: 'strong',
			overrides: 'b'
		},
		coreStyles_italic: {
			element: 'em',
			overrides: 'i'
		},
		coreStyles_underline: {
			element: 'u'
		},
		coreStyles_strike: {
			element: 'strike'
		},
		coreStyles_subscript: {
			element: 'sub'
		},
		coreStyles_superscript: {
			element: 'sup'
		},
		colorButton_foreStyle: {
			element: 'span',
			styles: {
				color: '#(color)'
			},
			overrides: [{
				element: 'font',
				attributes: {
					color: null
				}
			}]
		},
		colorButton_backStyle: {
			element: 'span',
			styles: {
				'background-color': '#(color)'
			}
		},
		basicEntities: true,
		entities: true,
		entities_latin: true,
		entities_greek: true,
		entities_additional: '#39',
		find_highlight: {
			element: 'span',
			styles: {
				'background-color': '#004',
				color: '#fff'
			}
		},
		flashEmbedTagOnly: false,
		flashAddEmbedTag: true,
		flashConvertOnEdit: false,
		font_names: 'Arial/Arial, Helvetica, sans-serif;Comic Sans MS/Comic Sans MS, cursive;Courier New/Courier New, Courier, monospace;Georgia/Georgia, serif;Lucida Sans Unicode/Lucida Sans Unicode, Lucida Grande, sans-serif;Tahoma/Tahoma, Geneva, sans-serif;Times New Roman/Times New Roman, Times, serif;Trebuchet MS/Trebuchet MS, Helvetica, sans-serif;Verdana/Verdana, Geneva, sans-serif',
		font_defaultLabel: 'Arial',
		font_style: {
			element: 'span',
			styles: {
				'font-family': '#(family)'
			},
			overrides: [{
				element: 'font',
				attributes: {
					face: null
				}
			}]
		},
		fontSize_sizes: '8/8px;9/9px;10/10px;11/11px;12/12px;14/14px;16/16px;18/18px;20/20px;22/22px;24/24px;26/26px;28/28px;36/36px;48/48px;72/72px',
		fontSize_defaultLabel: '12',
		fontSize_style: {
			element: 'span',
			styles: {
				'font-size': '#(size)'
			},
			overrides: [{
				element: 'font',
				attributes: {
					size: null
				}
			}]
		},
		format_tags: 'div;h1;h2;h3;h4;h5;h6;pre',
		format_div: {
			element: 'div'
		},
		format_pre: {
			element: 'pre'
		},
		format_h1: {
			element: 'h1'
		},
		format_h2: {
			element: 'h2'
		},
		format_h3: {
			element: 'h3'
		},
		format_h4: {
			element: 'h4'
		},
		format_h5: {
			element: 'h5'
		},
		format_h6: {
			element: 'h6'
		},
		image_removeLinkByEmptyURL: true,
		blockedKeystrokes: [
			0x110000 + 66, // CTRL + B
			0x110000 + 73, // CTRL + I
			0x110000 + 85 // CTRL + U
		],
		keystrokes: [
			[0x110000 + 66, 'bold'], // CTRL + B
			[0x110000 + 73, 'italic'], // CTRL + I
			[0x110000 + 85, 'underline'], // CTRL + U
			[0x110000 + 90, 'undo'], // CTRL + Z
			[0x110000 + 89, 'redo'], // CTRL + Y
			[0x110000 + 0x220000 + 90, 'redo'] // CTRL + SHIFT + Z
		],
		linkShowAdvancedTab: true,
		linkShowTargetTab: true,

		//removeFormatTags: 'b,big,code,del,dfn,em,font,i,ins,kbd,q,samp,small,span,strike,strong,sub,sup,tt,u,var',
		//removeFormatTags: 'ol,ul,li,h1,h2,h3,h4,h5,h6,pre,address,div,b,big,code,del,dfn,em,font,i,ins,kbd,q,samp,small,span,strike,strong,sub,sup,tt,u,var',
		removeFormatTags: 'h1,h2,h3,h4,h5,h6,pre,address,b,big,code,del,dfn,em,font,i,ins,kbd,q,samp,small,span,strike,strong,sub,sup,tt,u,var',
		removeFormatAttributes: 'class,style,lang,width,height,align,hspace,valign',

		templates_replaceContent: true,
		toolbarLocation: 'top',
		toolbar_Basic: [],
		toolbar_Full: [
			{
				name: 'document',
				items: ['Source', '-', 'Save', 'NewPage', 'DocProps', 'Preview',
					'Print', '-', 'Templates']
			}, {
				name: 'clipboard',
				items: ['Cut', 'Copy', 'Paste', 'PasteText', 'PasteFromWord', '-',
					'Undo', 'Redo']
			}, {
				name: 'editing',
				items: ['Find', 'Replace', '-', 'SelectAll', '-', 'SpellChecker',
					'Scayt']
			}, {
				name: 'forms',
				items: ['Form', 'Checkbox', 'Radio', 'TextField', 'Textarea',
					'Select', 'Button', 'ImageButton', 'HiddenField']
			}, '/', {
				name: 'basicstyles',
				items: ['Bold', 'Italic', 'Underline', 'Strike', 'Subscript',
					'Superscript', '-', 'RemoveFormat']
			}, {
				name: 'paragraph',
				items: ['NumberedList', 'BulletedList', '-', 'Outdent', 'Indent', '-',
					'Blockquote', 'CreateDiv', '-', 'JustifyLeft', 'JustifyCenter',
					'JustifyRight', 'JustifyBlock', '-', 'BidiLtr', 'BidiRtl']
			}, {
				name: 'links',
				items: ['Link', 'Unlink', 'Anchor']
			}, {
				name: 'insert',
				items: ['Image', 'Flash', 'Table', 'HorizontalRule', 'Smiley',
					'SpecialChar', 'PageBreak', 'Iframe']
			}, '/', {
				name: 'styles',
				items: ['Styles', 'Format', 'Font', 'FontSize']
			}, {
				name: 'colors',
				items: ['TextColor', 'BGColor']
			}, {
				name: 'tools',
				items: ['Maximize', 'ShowBlocks', '-', 'About']
			}
		],
		toolbar: 'Basic',
		toolbarCanCollapse: false,
		disableObjectResizing: false,
		disableNativeTableHandles: false,
		disableNativeSpellChecker: true,
		ignoreEmptyParagraph: true,
		startupMode: 'wysiwyg',
		editingBlock: true,
		customConfig: '',
		plugins: [
			'basicstyles',
			'bidi',
			'button',
			'clipboard',
			'elementspath',
			'enterkey',
			'entities',
			'htmldataprocessor',
			'indent',
			'justify',
			'keystrokes',
			'list',
			'pastefromword',
			'removeformat',
			'resize',
			'sourcearea',
			'tab',
			'undo',
			'wysiwygarea'
		].join(',')
	},
	ckEditorLoaded: false,

	initComponent: function() {
		Terrasoft.HtmlEdit.superclass.initComponent.call(this);
		var stringList = Ext.StringList('WC.HtmlEdit');
		this.speliingMessage = Ext.StringList('WC.Common').getValue('LoadMask.Loading');
		this.spellMenuStringList = stringList;
		this.noWordVariantsCaption = stringList.getValue('SpellingMenu.NoWordVariants');
		this.editWordCaption = stringList.getValue('SpellingMenu.EditWord');
		if (this.linkButtonVisible && this.toolbarVisible && stringList) {
			this.createLinkText = stringList.getValue('Message.PleaseEnterUrl');
		}
		var ckEditorContentCss = this.ckEditorConfig.contentsCss;
		var defaultCssProperties = this.ckDocumentDefaultCssProperties;
		for (var cssProperty in defaultCssProperties) {
			if (defaultCssProperties.hasOwnProperty(cssProperty)) {
				ckEditorContentCss =
					ckEditorContentCss.replace('#(' + cssProperty + ')', defaultCssProperties[cssProperty]);
			}
		}
		this.ckEditorConfig.contentsCss = ckEditorContentCss;
		this.ckEditorLoaded = false;
		if (!this.designMode) {
			if (!window.CKEDITOR) {
				var isEnabled = this.enabled;
				this.enabled = false;
				this.setEnabled(false);
				this.startEnabled = isEnabled;
				var ckEditorScriptUrl = String.format("{0}/terrasoft.axd?rm={1}&r={2}",
					Terrasoft.applicationPath, this.ckEditorResourceManagerName, this.ckEditorResourceItemName);
				Terrasoft.ScriptLoader.loadScript(ckEditorScriptUrl, this.onCkEditorLoaded, null, this);
			} else {
				this.ckEditorLoaded = true;
			}
		}
		this.addEvents(
			'editmodechange',
			'imageloaded',
			'beforeimageadd'
		);
	},

	onCkEditorLoaded: function() {
		this.ckEditorLoaded = true;
		// TODO : Убрать после реализации нормальной локализации
		CKEDITOR.lang.ru.editor = '';
		CKEDITOR.lang.ru.editorTitle = '';
		this.initCkEditor();
	},

	markRequired: function(required) {
		if (required == undefined) {
			return;
		}
		this.required = required;
		var labelEl = this.getLabelEl();
		labelEl && labelEl[required ? "addClass" : "removeClass"]([this.requiredClass, 'x-display-name-required']);
		if (this.designMode) {
			this.validate(true);
		}
	},

	markInvalid: function(msg) {
		if (!this.rendered || !this.container) {
			return;
		}
		if (!this.ckEditorInitialized) {
			return;
		}
		var backgroundColor = this.enabled ? '#FEEEEB' : '#ebeff5';
		if (this.required) {
			var funcName = this.enabled ? 'addClass' : 'removeClass';
			this.wrap[funcName](this.invalidClass);
		}
		var ckEditor = this.ckEditor;
		if (ckEditor) {
			var mode = ckEditor.getMode().name;
			if (mode == 'source') {
				ckEditor.textarea.setStyle('background-color', backgroundColor);
			} else {
				var ckBody = ckEditor.document.getBody();
				var bodyClass = this.enabled ? '' : this.ckEditorDisableClass;
				bodyClass += ' ' + this.ckEditorInvalidClass;
				ckEditor.config.bodyClass = bodyClass;
				ckBody.addClass('terrasoft-htmledit-invalid');
			}
		}
		if (this.preventMark || this.required) {
			return;
		}
		msg = msg || this.invalidText;
		Ext.FormValidator.addMessage(Ext.Link.applyLinks(String.format(msg, this.id), this.getLinkConfig()));
		this.fireEvent('invalid', this, msg);
	},

	clearInvalid: function() {
		if (!this.rendered || !this.container) {
			return;
		}
		if (!this.ckEditorInitialized) {
			return;
		}
		this.wrap.removeClass(this.invalidClass);
		var ckEditor = this.ckEditor;
		if (ckEditor) {
			var backgroundColor = this.enabled ? '#ffffff' : '#ebeff5';
			var mode = ckEditor.getMode().name;
			if (mode == 'source') {
				ckEditor.textarea.setStyle('background-color', backgroundColor);
			} else {
				if (!ckEditor.document) {
					return;
				}
				var ckBody = ckEditor.document.getBody();
				ckEditor.config.bodyClass = this.enabled ? '' : this.ckEditorDisableClass;
				ckBody.removeClass(this.ckEditorInvalidClass);
			}
		}
		if (this.preventMark) {
			return;
		}
		var vmp = Ext.FormValidator.validationMessagePanel;
		if (vmp = Ext.getCmp(vmp)) {
			vmp.remove(this.id + '_invalid');
		}
		this.fireEvent('valid', this);
	},

	setEdges: function(edgesValue) {
		this.edges = edgesValue;
		if (!this.rendered) {
			return;
		}
		var resizeEl = this.getResizeEl();
		resizeEl.addClass("x-container-border");
		var style = resizeEl.dom.style;
		if (edgesValue) {
			var edges = edgesValue.split(" ");
			style.borderTopStyle = (edges[0] == 1 ? 'solid' : 'none');
			style.borderRightStyle = (edges[1] == 1 ? 'solid' : 'none');
			style.borderBottomStyle = (edges[2] == 1 ? 'solid' : 'none');
			style.borderLeftStyle = (edges[3] == 1 ? 'solid' : 'none');
			this.onResize(this.getWidth(), this.getHeight());
		} else {
			style.borderStyle = 'none';
		}
	},

	setToolbarVisible: function(toolbarVisible) {
		this.toolbarVisible = toolbarVisible;
		if (!this.rendered) {
			return;
		}
		var toolbar = this.toolbar;
		toolbar.setVisible(toolbarVisible);
		var toolbarHeight = toolbarVisible ? toolbar.getHeight() : 0;
		var resultHeight = this.getHeight() - this.wrap.getFrameWidth('tb') - toolbarHeight;
		if (resultHeight < 0) {
			resultHeight = 0;
		}
		this.elWrap.setHeight(resultHeight);
	},

	setEnabled: function(enabled) {
		var column = this.getColumn();
		if (column && !this.dataSource.canEditColumn(column)) {
			enabled = false;
		}
		if (!this.ckEditorInitialized) {
			this.startEnabled = enabled;
			return;
		}
		this.enabled = enabled;
		if (!this.rendered) {
			return;
		}
		Terrasoft.HtmlEdit.superclass.setEnabled.call(this, enabled);
		this.actualizeToolbar();
		if (!this.designMode) {
			var ckEditor = this.ckEditor;
			var mode = ckEditor.getMode().name;
			if (mode !== 'source') {
				var ckEditorDisableClass = this.ckEditorDisableClass;
				var ckEditorInvalidClass = this.ckEditorInvalidClass;
				var oldBodyClass = ckEditor.config.bodyClass;
				var bodyClass = this.enabled ? '' : ckEditorDisableClass;
				var regex = new RegExp(ckEditorInvalidClass);
				if (regex.test(oldBodyClass)) {
					bodyClass += ' ' + ckEditorInvalidClass;
				}
				ckEditor.config.bodyClass = bodyClass;
			}
			ckEditor.setReadOnly(!enabled);
		}
	},

	setFormatSelectionVisible: function(formatSelectionVisible) {
		this.formatSelectionVisible = formatSelectionVisible;
		if (!this.rendered) {
			return;
		}
		this.setToolbarItemVisible(['combobox-format'], formatSelectionVisible);
	},

	setPropertiesByColumn: function(column) {
		if (!column) {
			return;
		}
		var caption = column.caption;
		if (this.isDefaultPropertyValue('caption') && caption !== undefined) {
			this.setCaption(caption);
		}
		var required = column.required;
		if (this.isDefaultPropertyValue('required') && required !== undefined) {
			this.setRequired(required);
		}
		var size = this.getFieldSize();
		if (size) {
			this.setMaxLength(size);
		}
	},

	setFontNameSelectionVisible: function(fontNameSelectionVisible) {
		this.fontNameSelectionVisible = fontNameSelectionVisible;
		if (!this.rendered) {
			return;
		}
		this.setToolbarItemVisible(['combobox-font'], fontNameSelectionVisible);
	},

	setFontSizeSelectionVisible: function(fontSizeSelectionVisible) {
		this.fontSizeSelectionVisible = fontSizeSelectionVisible;
		if (!this.rendered) {
			return;
		}
		this.setToolbarItemVisible(['combobox-fontSize'], fontSizeSelectionVisible);
	},

	setFontStyleButtonsVisible: function(fontStyleButtonsVisible) {
		this.fontStyleButtonsVisible = fontStyleButtonsVisible;
		if (!this.rendered) {
			return;
		}
		this.setToolbarItemVisible(['bold', 'underline', 'italic'], fontStyleButtonsVisible);
	},

	setColorButtonsVisible: function(colorButtonsVisible) {
		this.colorButtonsVisible = colorButtonsVisible;
		if (!this.rendered) {
			return;
		}
		this.setToolbarItemVisible(['forecolor', 'backcolor'], colorButtonsVisible);
	},

	setListButtonsVisible: function(listButtonsVisible) {
		this.listButtonsVisible = listButtonsVisible;
		if (!this.rendered) {
			return;
		}
		this.setToolbarItemVisible(['insertorderedlist', 'insertunorderedlist'], listButtonsVisible);
	},

	setAlignmentButtonsVisible: function(alignmentButtonsVisible) {
		this.alignmentButtonsVisible = alignmentButtonsVisible;
		if (!this.rendered) {
			return;
		}
		this.setToolbarItemVisible(['justifyleft', 'justifycenter', 'justifyright'], alignmentButtonsVisible);
	},

	setLinkButtonVisible: function(linkButtonVisible) {
		this.linkButtonVisible = linkButtonVisible;
		if (!this.rendered) {
			return;
		}
		this.setToolbarItemVisible('createlink', linkButtonVisible);
	},

	setImageButtonVisible: function(imageButtonVisible) {
		this.imageButtonVisible = imageButtonVisible;
		if (!this.rendered) {
			return;
		}
		this.setToolbarItemVisible('createImage', imageButtonVisible);
	},

	setSpellTextButtonVisible: function(spellTextButtonVisible) {
		this.spellTextButtonVisible = spellTextButtonVisible = spellTextButtonVisible && this.isSetDefaultSpellChecker();
		if (!this.rendered) {
			return;
		}
		this.setToolbarItemVisible('spelltext', spellTextButtonVisible);
	},

	setFormatedTextButtonVisible: function(formatedTextButtonVisible) {
		this.formatedTextButtonVisible = formatedTextButtonVisible;
		if (!this.rendered) {
			return;
		}
		this.setToolbarItemVisible('formatedText', formatedTextButtonVisible);
	},

	setPlainTextButtonVisible: function(plainTextButtonVisible) {
		this.plainTextButtonVisible = plainTextButtonVisible;
		if (!this.rendered) {
			return;
		}
		this.setToolbarItemVisible('plainText', plainTextButtonVisible);
	},

	setSourceEditButtonVisible: function(sourceEditButtonVisible) {
		this.sourceEditButtonVisible = sourceEditButtonVisible;
		if (!this.rendered) {
			return;
		}
		this.setToolbarItemVisible('source', sourceEditButtonVisible);
	},

	setToolbarItemVisible: function(itemPropertyName, itemVisible) {
		var toolbar = this.toolbar;
		toolbar.beginContentUpdate();
		if (Ext.isArray(itemPropertyName)) {
			for (var i = 0, itemsLength = itemPropertyName.length; i < itemsLength; i++) {
				var itemName = itemPropertyName[i];
				toolbar[itemName].setVisible(itemVisible);
			}
		} else {
			toolbar[itemPropertyName].setVisible(itemVisible);
		}
		this.actualizeToolBarSeparators();
		toolbar.endContentUpdate();
		toolbar.doLayout();
	},

	actualizeToolBarSeparators: function() {
		var toolbarItems = this.toolbar.items;
		var items = toolbarItems.items;
		var itemsLength = toolbarItems.length;
		var isFirstItem = true;
		for (var i = 0; i < itemsLength; i++) {
			var item = items[i];
			if (item.hidden === true) {
				isFirstItem = false;
			}
			var itemXType = item.getXType();
			if (itemXType == 'spacer') {
				var isVisible = item.checkIsVisible.call(this);
				item.setVisible(!isFirstItem && isVisible);
				isFirstItem = false;
			}
		}
	},

	getStyles: function(stylesConfig, styleDefinition, stylePropertyName) {
		var styles = {
			store: [],
			styleNames: [],
			values: {}
		};
		var entities = stylesConfig.split(';');
		for (var i = 0; i < entities.length; i++) {
			var entity = entities[i];
			var parts = entity.split('/');
			var styleName = parts[0];
			var styleValue = parts[1];
			styles.store.push(new Array(styleName));
			styles.styleNames.push(styleName);
			var style = null;
			if (stylePropertyName) {
				style = {};
				style[stylePropertyName] = styleValue || styleName;
			}
			var styleDef = styleDefinition;
			if (typeof styleDefinition == 'function') {
				styleDef = styleDefinition(styleName);
			}
			var ckEditorStyle = new CKEDITOR.style(styleDef, style);
			ckEditorStyle._.definition.name = styleName;
			styles.values[styleName] = ckEditorStyle;
		}
		return styles;
	},

	onToolbarComboBoxSelect: function(comboBox, record, index, oldValue) {
		var ckEditor = this.ckEditor;
		ckEditor.focus();
		var selection = ckEditor.document.getSelection();
		if (!selection) {
			return;
		}
		var value = Ext.decode(record).value;
		this.applySelectedStyle(comboBox, value, value == oldValue);
		ckEditor.updateElement();
		this.onFocus();
	},

	createToolbarComboBox: function(config) {
		var comboBox = new Terrasoft.ComboBox({
			width: config.width,
			disabled: this.designMode,
			styleName: config.styleName,
			enabledEditModes: {
				formatedTextEditMode: true,
				sourceEditMode: false,
				plainTextEditMode: false,
				spellMode: false
			}
		});
		comboBox.setVisible(config.visible);
		this.reinitComboboxStore(comboBox, config.styles);
		comboBox.on('select', function(el, record, index, oldValue) {
			this.onToolbarComboBoxSelect(el, record, index, oldValue);
		}, this);
		return this.toolbar[config.itemId] = comboBox;
	},

	onCkEditorSelectionChange: function(event) {
		var currentStyle = this.getValue();
		var elementPath = event.data.path;
		var elements = elementPath.elements;
		var styles = this.styles;
		for (var i = 0, element; i < elements.length; i++) {
			element = elements[i];
			for (var style in styles.values) {
				if (styles.values[style].checkElementRemovable(element, true)) {
					if (style != currentStyle) {
						this.setValue(style);
					}
					return;
				}
			}
		}
		this.setValue(this.defaultValue);
	},

	onCkEditorCommandStateChange: function(event, b) {
		switch (event.sender.state) {
			case CKEDITOR.TRISTATE_DISABLED:
				this.toggle(false);
				break;
			case CKEDITOR.TRISTATE_ON:
				this.toggle(true);
				break;
			case CKEDITOR.TRISTATE_OFF:
				this.toggle(false);
				break;
		}
	},

	subscribeToolButton: function(button) {
		if (!this.designMode && this.ckEditorInitialized) {
			var ckEditor = this.ckEditor;
			var ckCommand = ckEditor.getCommand(button.commandName);
			ckCommand && ckCommand.on('state', this.onCkEditorCommandStateChange, button);
		}
	},

	reinitComboboxStore: function(comboBox, styles) {
		comboBox.store = new Ext.data.SimpleStore({
			fields: ['value'],
			data: styles.store
		});
		comboBox.styles = styles;
		comboBox.displayField = 'value';
		if (!this.designMode && this.ckEditorInitialized) {
			this.ckEditor.on('selectionChange', function(event) {
				this.onCkEditorSelectionChange.call(comboBox, event);
			}, this);
		}
	},

	getCkEditorStyles: function() {
		var ckEditorStyles = {
			fontsStyles: [],
			fontsSizeStyles: [],
			formattingStyles: [],
			foreColorStyles: [],
			backColorStyles: []
		};
		if (!this.designMode && this.ckEditorInitialized) {
			var ckEditorConfig = this.ckEditor.config;
			ckEditorStyles.fontsStyles = this.getStyles(ckEditorConfig.font_names, ckEditorConfig.font_style, 'family');
			ckEditorStyles.fontsSizeStyles =
				this.getStyles(ckEditorConfig.fontSize_sizes, ckEditorConfig.fontSize_style, 'size');
			ckEditorStyles.formattingStyles = this.getStyles(
				ckEditorConfig.format_tags,
				function(styleName) {
					return ckEditorConfig['format_' + styleName];
				}
			);
			var palette = Terrasoft.ColorPalette.prototype.colors;
			var foreColors = [];
			var backColors = [];
			for (var i = palette.length; i--;) {
				var item = i + '/#' + palette[i];
				foreColors.unshift('foreColor' + item);
				backColors.unshift('backColor' + item);
			}
			ckEditorStyles.foreColorStyles =
				this.getStyles(foreColors.join(';'), ckEditorConfig.colorButton_foreStyle, 'color');
			ckEditorStyles.backColorStyles =
				this.getStyles(backColors.join(';'), ckEditorConfig.colorButton_backStyle, 'color');
		}
		return ckEditorStyles;
	},

	applySelectedStyle: function(comboBox, styleName, isStyleRemove) {
		var style = comboBox.styles.values[styleName];
		style[isStyleRemove ? 'remove' : 'apply'](this.ckEditor.document);
	},

	applyColorStyle: function(ckEditorInstance, type, color) {

		function isUnstylable(ele) {
			return (ele.getAttribute('contentEditable') == 'false') || ele.getAttribute('data-nostyle');
		}

		var config = ckEditorInstance.config;
		var colorStyle = config['colorButton_' + type + 'Style'];
		colorStyle.childRule = type == 'back' ?
			function(element) {
				return isUnstylable(element);
			}
			:
			function(element) {
				return element.getName() != 'a' || isUnstylable(element);
			};
		new CKEDITOR.style(colorStyle, {color: color}).apply(ckEditorInstance.document);
	},

	onColorMenuSelect: function(color, colorType) {
		var ckEditor = this.ckEditor;
		var selection = ckEditor.document.getSelection();
		if (!selection) {
			return;
		}
		this.applyColorStyle(ckEditor, colorType, color);
		ckEditor.focus();
	},

	createColorMenu: function(colorType) {
		var colorMenu = new Ext.menu.ColorMenu({
			focus: Ext.emptyFn,
			plain: true,
			allowReselect: true,
			value: 'FFFFFF',
			clickEvent: 'mousedown',
			colorType: colorType
		});
		var htmlEdit = this;
		colorMenu.on('select', function(colorPalette, color) {
			htmlEdit.onColorMenuSelect(color, this.colorType);
		}, colorMenu);
		return colorMenu;
	},

	createToolButton: function(config) {
		var toolbar = this.toolbar;
		var itemId = config.itemId;
		if (itemId == '-') {
			var spacer = new Ext.Spacer({
				hidden: !config.visible,
				stripeVisible: true,
				checkIsVisible: config.checkIsVisible
			});
			return toolbar['sep-' + config.toggle] = spacer;
		} else {
			var controlConfig = Ext.apply({
				imageAsSprite: true,
				allowDepress: true,
				scope: this,
				isHtmlEditTool: true,
				enabledEditModes: {
					formatedTextEditMode: true,
					sourceEditMode: false,
					plainTextEditMode: false,
					spellMode: false
				},
				imageConfig: {
					source: 'ResourceManager',
					resourceManagerName: 'Terrasoft.UI.WebControls',
					resourceItemName: this.btnImageNamePrefix + itemId + '.png'
				},
				handler: this.executeCommand,
				enabled: !this.designMode,
				toggleGroup: config.toggle ? (config.group || this.id + '-' + itemId) : '',
				hidden: !config.visible
			}, config);
			delete controlConfig.toggle;
			delete controlConfig.visible;
			var button = new Terrasoft.Button(controlConfig);
			return toolbar[itemId] = button;
		}
	},

	createToolbar: function() {
		var btnImageNamePrefix = this.btnImageNamePrefix;
		var toolbar = this.toolbar = new Terrasoft.ControlLayout({
			id: this.id + '_' + 'toolbar',
			edges: "0 0 1 0",
			displayStyle: 'topbar',
			enabled: !this.designMode,
			width: '100%',
			isHtmlEditTool: true
		});
		toolbar.add(this.createToolbarComboBox({
			itemId: 'combobox-format',
			visible: this.formatSelectionVisible,
			width: 115,
			styles: [],
			styleName: 'formattingStyles'
		}));
		toolbar.add(this.createToolbarComboBox({
			itemId: 'combobox-font',
			visible: this.fontNameSelectionVisible,
			width: 115,
			styles: [],
			styleName: 'fontsStyles'
		}));
		toolbar.add(this.createToolbarComboBox({
			itemId: 'combobox-fontSize',
			visible: this.fontSizeSelectionVisible,
			width: 50,
			styles: [],
			styleName: 'fontsSizeStyles'
		}));
		toolbar.add(this.createToolButton({
			itemId: '-',
			visible: this.fontStyleButtonsVisible,
			toggle: 'fontstyle',
			checkIsVisible: function() {
				return this.fontStyleButtonsVisible;
			}
		}));
		toolbar.add(
			this.createToolButton({
				itemId: 'bold',
				visible: this.fontStyleButtonsVisible,
				commandName: 'bold'
			}),
			this.createToolButton({
				itemId: 'italic',
				visible: this.fontStyleButtonsVisible,
				commandName: 'italic'
			}),
			this.createToolButton({
				itemId: 'underline',
				visible: this.fontStyleButtonsVisible,
				commandName: 'underline'
			})
		);
		toolbar.add(this.createToolButton({
			itemId: '-',
			visible: this.colorButtonsVisible,
			toggle: 'color',
			checkIsVisible: function() {
				return this.colorButtonsVisible;
			}
		}));
		var foreColorBtn = this.createToolButton({
			itemId: 'forecolor',
			visible: this.colorButtonsVisible,
			commandName: 'forecolor',
			commandData: 'color',
			menu: this.createColorMenu('fore')
		});
		foreColorBtn.owner = foreColorBtn;
		var backColorBtn = this.createToolButton({
			itemId: 'backgroundcolor',
			visible: this.colorButtonsVisible,
			commandName: 'backcolor',
			commandData: 'color',
			menu: this.createColorMenu('back')
		});
		backColorBtn.owner = backColorBtn;
		toolbar.add(foreColorBtn, backColorBtn);
		toolbar.add(this.createToolButton({
			itemId: '-',
			visible: this.listButtonsVisible,
			toggle: 'list',
			checkIsVisible: function() {
				return this.listButtonsVisible;
			}
		}));
		toolbar.add(
			this.createToolButton({
				itemId: 'orderedlist',
				visible: this.listButtonsVisible,
				commandName: 'numberedlist'
			}),
			this.createToolButton({
				itemId: 'unorderedlist',
				visible: this.listButtonsVisible,
				commandName: 'bulletedlist'
			})
		);
		toolbar.add(this.createToolButton({
			itemId: '-',
			visible: this.alignmentButtonsVisible,
			toggle: 'justify',
			checkIsVisible: function() {
				return this.alignmentButtonsVisible;
			}
		}));
		toolbar.add(
			this.createToolButton({
				itemId: 'justifyleft',
				visible: this.alignmentButtonsVisible,
				toggle: true,
				group: 'justifytext',
				commandName: 'justifyleft'
			}),
			this.createToolButton({
				itemId: 'justifycenter',
				visible: this.alignmentButtonsVisible,
				toggle: true,
				group: 'justifytext',
				commandName: 'justifycenter'
			}),
			this.createToolButton({
				itemId: 'justifyright',
				visible: this.alignmentButtonsVisible,
				toggle: true,
				group: 'justifytext',
				commandName: 'justifyright'
			})
		);
		toolbar.add(this.createToolButton({
			itemId: '-',
			visible: this.linkButtonVisible || this.imageButtonVisible,
			toggle: 'link',
			checkIsVisible: function() {
				return this.linkButtonVisible || this.imageButtonVisible;
			}
		}));
		toolbar.add(
			this.createToolButton({
				itemId: 'image',
				visible: this.imageButtonVisible,
				handler: this.createImageHandler
			}),
			this.createToolButton({
				itemId: 'link',
				visible: this.linkButtonVisible,
				handler: this.createLink
			})
		);
		var spellTextButtonVisible = this.isSpellTextButtonVisible();
		toolbar.add(this.createToolButton({
			itemId: '-',
			visible: spellTextButtonVisible,
			toggle: 'spelltext',
			checkIsVisible: function() {
				return this.spellTextButtonVisible;
			}
		}));
		var spellChecker = this.spellChecker = new Terrasoft.SpellChecker();
		spellChecker.initComponent();
		toolbar.add(this.createToolButton({
			itemId: 'spelltext',
			visible: spellTextButtonVisible,
			enabledEditModes: {
				formatedTextEditMode: true,
				sourceEditMode: false,
				plainTextEditMode: true,
				spellMode: true
			},
			toggle: true,
			handler: function() {
				this.toggleSpellingMode(!this.spellMode);
				this.focus();
			}
		}));

		toolbar.add(this.createToolButton({
			itemId: '-',
			visible: this.sourceEditButtonVisible || this.formatedTextButtonVisible || this.plainTextButtonVisible,
			toggle: 'editormode',
			checkIsVisible: function() {
				return this.sourceEditButtonVisible ||
					this.formatedTextButtonVisible ||
					this.plainTextButtonVisible;
			}
		}));
		toolbar.add(this.createToolButton({
			editorMode: 'formatedTextEditMode',
			itemId: 'formatedText',
			visible: this.formatedTextButtonVisible,
			enabledEditModes: {
				formatedTextEditMode: true,
				sourceEditMode: true,
				plainTextEditMode: true,
				spellMode: false
			},
			toggle: true,
			group: 'editorMode',
			allowDepress: false,
			pressed: this.mode == 'formatedTextEditMode',
			imageConfig: {
				source: 'ResourceManager',
				resourceManagerName: 'Terrasoft.UI.WebControls',
				resourceItemName: btnImageNamePrefix + 'html.png'
			},
			handler: function(btn) {
				if (btn.enabled !== true) {
					return;
				}
				this.toggleEditorMode(btn.editorMode);
			}
		}));
		toolbar.add(this.createToolButton({
			editorMode: 'plainTextEditMode',
			itemId: 'plaintext',
			visible: this.plainTextButtonVisible,
			enabledEditModes: {
				formatedTextEditMode: true,
				sourceEditMode: true,
				plainTextEditMode: true,
				spellMode: false
			},
			toggle: true,
			allowDepress: false,
			pressed: this.mode == 'plainTextEditMode',
			group: 'editorMode',
			handler: function(btn) {
				if (btn.enabled !== true) {
					return;
				}
				this.toggleEditorMode(btn.editorMode);
			}
		}));
		toolbar.add(this.createToolButton({
			editorMode: 'sourceEditMode',
			itemId: 'sourceedit',
			visible: this.sourceEditButtonVisible,
			enabledEditModes: {
				formatedTextEditMode: true,
				sourceEditMode: true,
				plainTextEditMode: true,
				spellMode: false
			},
			toggle: true,
			allowDepress: false,
			pressed: this.mode == 'sourceEditMode',
			group: 'editorMode',
			handler: function(btn) {
				if (btn.enabled !== true) {
					return;
				}
				this.toggleEditorMode(btn.editorMode);
			}
		}));

		toolbar.add(this.createToolButton({
			itemId: '-',
			visible: this.formatPainterButtonVisible,
			toggle: 'formatpainter',
			checkIsVisible: function() {
				return true;
			}
		}));
		toolbar.add(this.createToolButton({
			itemId: 'formatpainter',
			visible: this.formatPainterButtonVisible,
			toggle: 'formatpainter',
			handler: this.initFormatPainter()
		}));

		toolbar.render(this.wrap.dom.firstChild);
		var tbItems = toolbar.items.items;
		for (var i = 0; i < tbItems.length; i++) {
			var item = tbItems[i];
			item.getResizeEl().unselectable();
			item.canFocus = false;
		}
		toolbar.el.on('click', function(e) {
			e.preventDefault();
		});
	},

	createImageHandler: function() {
		if (this.hasListener('beforeimageadd')) {
			this.fireEvent('beforeimageadd', this, this.showCreateImageWindow);
			return;
		}
		this.showCreateImageWindow();
	},

	prepareSpellMode: function() {
		if (this.plainTextEditMode) {
			var ckEditor = this.ckEditor;
			this.elWrap.setStyle('display', 'none');
			var spellingEl = this.spellingEl;
			spellingEl.show();
			var value = ckEditor.textarea.getValue();
			if (spellingEl.dom.innerText !== undefined) {
				spellingEl.dom.innerText = value;
			} else {
				spellingEl.dom.textContent = value;
			}
		}
	},

	toggleSpellingMode: function(spellMode) {
		this.spellMode = spellMode;
		this.actualizeToolbar();
		var value;
		if (this.spellMode) {
			this.prepareSpellMode();
			this.spellText(this.plainTextEditMode ? 'plain' : 'html');
		} else {
			var ckEditor = this.ckEditor;
			if (this.plainTextEditMode) {
				// проверить нужно ли отписывать span-ы от событий
				var spellingEl = this.spellingEl;
				var spellingElDom = this.spellingEl.dom;
				value = spellingElDom.innerText;
				if (!value) {
					value = spellingElDom.innerHTML;
					value = value.replace(/<br[\s\/]*>|<\/p>/gi, '\n');
					value = value.replace(/<[^>]+>|<\/\w+>/gi, '');
					value = Ext.util.Format.htmlDecode(value);
				}
				ckEditor.setData(value);
				spellingEl.hide();
				this.elWrap.setStyle('display', '');
				spellingEl.dom.innerHTML = '';
				this.spellErrors = null;
			} else {
				var errors = this.spellErrors;
				ckEditor.removeListener('key', this.onCkEditorSpellingModeKeyPressed, this);
				for (var i = 0; i < errors.length; i++) {
					var error = errors[i];
					var ckSpanNode = ckEditor.document.$.getElementById(this.id + '_error_' + error.errorNumber);
					if (!ckSpanNode) {
						continue;
					}
					var ckSpanEl = new CKEDITOR.dom.element(ckSpanNode);
					ckSpanEl.removeAllListeners();
					if (ckSpanNode.outerHTML) {
						ckSpanNode.outerHTML = ckSpanNode.innerHTML;
					} else {
						var textNode = ckEditor.document.$.createTextNode(ckSpanNode.innerHTML);
						var ckSpanParentNode = ckSpanNode.parentNode;
						ckSpanParentNode.insertBefore(textNode, ckSpanNode);
						ckSpanParentNode.removeChild(ckSpanNode);
					}
				}
				this.spellErrors = null;
				ckEditor.updateElement();
			}
		}
	},

	spellText: function(format) {
		this.spellErrors = null;
		var spellChecker = this.spellChecker;
		spellChecker.on('textspelled', this.onTextChecked, this);
		this.wrap.mask(this.speliingMessage, 'x-mask-loading blue', true, false, true);
		var valueToSpell = this.getValue();
		spellChecker.spell(valueToSpell, {
			format: format
		});
	},

	onTextChecked: function(spellChecker, errors) {
		errors = errors.sort(function(a, b) {
			return a.wordPosition < b.wordPosition ? 1 : -1;
		});
		this.spellErrors = errors;
		this.highlightText(errors);
		this.wrap.unmask();
		spellChecker.un('textspelled', this.onTextChecked, this);
	},

	highlightText: function(errors) {
		var ckEditor = this.ckEditor;
		var value = this.getValue();
		var wLineImageConfig = {
			source: 'ResourceManager',
			resourceManagerName: 'Terrasoft.UI.WebControls',
			resourceItemName: 'htmledit-spellchecker-wline.png'
		};
		var imageUrl = this.getImageSrc(wLineImageConfig);
		var errorLineStyle = "background: " + imageUrl + " repeat-x scroll left bottom transparent;";
		errorLineStyle += "cursor: default; ";
		var highlitingTemplate = '<span style="' + errorLineStyle + '" id="{1}" errorNumber="{2}">{0}</span>';
		var errorSpecWordTemplate = "@@error_{0}@@";
		for (var i = 0; i < errors.length; i++) {
			var error = errors[i];
			value = value.substring(0, error.wordPosition) +
				String.format(errorSpecWordTemplate, error.errorNumber) +
				value.substring(error.wordPosition + error.wrodLength);
		}
		var htmlEditor = this;
		if (this.plainTextEditMode) {
			value = Ext.util.Format.htmlEncode(value);
		}
		value = value.replace(/@@error_(\d+)@@/g, function(matchString, number) {
			var errorNumber = Number(number);
			if (isNaN(errorNumber)) {
				return matchString;
			}
			var error = htmlEditor.getErrorByNumber(errorNumber);
			var spanId = htmlEditor.id + '_error_' + error.errorNumber;
			return String.format(highlitingTemplate, error.originalWord, spanId, error.errorNumber);
		});
		this.setSpellValue(value, function() {
			htmlEditor.subscribeSpellMenuEvents(errors);
		});
		if (!this.plainTextEditMode) {
			ckEditor.document.getBody().disableContextMenu();
			ckEditor.on('key', this.onCkEditorSpellingModeKeyPressed, this);
		}
	},

	onCkEditorSpellingModeKeyPressed: function(ckEvent) {
		var spanEl = ckEvent.sender._.elementsPath.list[0];
		if (spanEl.getName() !== 'span') {
			return;
		}
		spanEl.setStyle('background', 'none');
		spanEl.removeAllListeners();
	},

	// TODO проверить можно ли удалить
	getSpellValue: function() {
		if (this.plainTextEditMode) {
			var ckSpellingEl = new CKEDITOR.dom.element(this.spellingEl.dom);
			return ckSpellingEl.getText();
		} else {
			return this.ckEditor.getData();
		}
	},

	setSpellValue: function(value, callback) {
		if (this.plainTextEditMode) {
			value = value.replace(/\r\n/gi, '\n');
			value = value.replace(/\n/gi, '<br />');
			this.spellingEl.update(value, false, callback);
		} else {
			this.ckEditor.setData(value, callback);
		}
	},

	getSpanElByError: function(error) {
		var spanElId = this.id + '_error_' + error.errorNumber;
		return this.getSpanElById(spanElId);
	},

	getSpanElById: function(id) {
		if (this.plainTextEditMode) {
			return Ext.fly(id);
		} else {
			var ckEl = this.ckEditor.document.$.getElementById(id);
			return new CKEDITOR.dom.element(ckEl);
		}
	},

	subscribeSpellMenuEvents: function(errors) {
		for (var i = 0; i < errors.length; i++) {
			var error = errors[i];
			var spanEl = this.getSpanElByError(error);
			spanEl.on('contextmenu', this.onSpellingContextMenuShow, this);
		}
	},

	fillSpellContextMenu: function(menu, spanNode) {
		var errorNumber = spanNode.getAttribute('errorNumber');
		var spanElId = spanNode.getAttribute('id');
		var error = this.getErrorByNumber(errorNumber);
		for (var i = 0; i < error.hints.length; i++) {
			var hint = error.hints[i];
			var menuItem = new Ext.menu.Item({
				id: this.id + '_hint' + i,
				spanElId: spanElId,
				caption: hint,
				hint: hint,
				tag: 'spellVariants'
			});
			menu.addItem(menuItem);
			menuItem.on('click', this.onSpellingContextMenuItemClick, this);
		}
		if (menu.items.length == 0) {
			menu.addItem(new Ext.menu.Item({
				id: this.id + '_NO_HINTS',
				caption: this.noWordVariantsCaption,
				enabled: false
			}));
		}
		this.addEditManuItem(menu, spanElId);
	},

	getSpellContextMenu: function() {
		var menu = this.menu;
		if (!menu) {
			menu = this.menu = new Ext.menu.Menu();
			menu.owner = this;
		}
		return menu;
	},

	onSpellingContextMenuShow: function(event) {
		if (event.stopEvent) {
			event.stopEvent();
		}
		if (event.cancel) {
			event.cancel();
		}
		var spanEl = event.sender ? event.sender : event.target;
		var menu = this.getSpellContextMenu();
		menu.removeAll();
		this.fillSpellContextMenu(menu, spanEl);
		var menuPosition;
		if (event.data) {
			event.data.preventDefault();
			var mouseEvent = event.data.$;
			var elWrap = this.elWrap;
			menuPosition = [
				mouseEvent.clientX + elWrap.getLeft(),
				mouseEvent.clientY + elWrap.getTop()
			];
		} else {
			menuPosition = event.xy;
		}
		var ckDocument = this.ckEditor.document;
		if (ckDocument) {
			ckDocument.on(Ext.isGecko ? 'DOMMouseScroll' : 'mousewheel', this.hideSpellingContextMenu, this);
			ckDocument.on('mousedown', this.hideSpellingContextMenu, this);
		} else {
			Ext.getDoc().on('mousewheel', this.hideSpellingContextMenu, this);
		}
		menu.showAt(menuPosition);
	},

	hideSpellingContextMenu: function() {
		var menu = this.menu;
		menu && menu.hide();
		var ckDocument = this.ckEditor.document;
		if (ckDocument) {
			var eventName = Ext.isGecko ? 'DOMMouseScroll' : 'mousewheel';
			ckDocument.removeListener(eventName, this.hideSpellingContextMenu, this);
			ckDocument.removeListener('mousedown', this.hideSpellingContextMenu, this);
		} else {
			Ext.getDoc().un('mousewheel', this.hideSpellingContextMenu, this);
		}
	},

	addEditManuItem: function(menu, spanElId) {
		if (!this.plainTextEditMode) {
			return;
		}
		menu.addSeparator();
		var editMenuItem = new Ext.menu.Item({
			id: this.id + '_edit',
			spanElId: spanElId,
			caption: this.editWordCaption,
			tag: 'editWord'
		});
		menu.addItem(editMenuItem);
		editMenuItem.on('click', this.onSpellingContextMenuItemClick, this);
	},

	insertTextEditEl: function(node, position) {
		if (position === 'insertAfter') {
			var textEl = Ext.DomHelper.insertAfter(node, {
					tag: 'input',
					type: "text",
					size: "20",
					autocomplete: "off"
				},
				true
			);
			return textEl;
		}
		return null;
	},

	applyEditorValue: function(editorNode, spanNode) {
		var spanEl = Ext.fly(spanNode);
		spanEl.setStyle('display', '');
		spanEl.setStyle('background', 'none');
		spanEl.dom.innerHTML = editorNode.value;
		spanEl.removeAllListeners();
	},

	removeNode: function(node) {
		node.parentNode.removeChild(node);
	},

	textEditorKeyHandler: function(event, el) {
		var key = event.getKey();
		if (key == event.ENTER) {
			this.applyEditorValue(el, el.previousSibling);
			this.removeNode(el);
		}
		/*
		if (key == event.TAB) {
			var spanNode = el.previousSibling;
			var errorNumber = spanNode.getAttribute('errorNumber') * 1;
			var spanElId = spanNode.getAttribute('id');
			this.applyEditorValue(el, spanNode);
			this.removeNode(el);
			var nextErrorNumber = errorNumber + event.shiftKey ? -1 : 1;

			var error = this.getErrorByNumber(nextErrorNumber);
			var spanEl = this.getSpanElByError(error);
			this.editErrorSpan(spanEl);

			spanEl.removeAllListeners();

			el.parentNode.removeChild(el);
		}
		*/
	},

	editErrorSpan: function(spanEl) {
		var textEl = this.insertTextEditEl(spanEl.dom, 'insertAfter');
		textEl.dom.value = spanEl.dom.innerHTML;
		// TODO добавить нормальные стили
		textEl.setStyle({
			//'border': '0px',
			'font-family': 'Courier New , Monospace',
			'font-size': 'small',
			'white-space': 'pre-wrap',
			'text-align': 'left'
		});
		spanEl.setStyle('display', 'none');
		textEl.on(Ext.isIE || Ext.isSafari3 ? 'keydown' : 'keypress', this.textEditorKeyHandler, this);
	},

	onSpellingContextMenuItemClick: function(menuItem, event, tag) {
		var spanEl = this.getSpanElById(menuItem.spanElId);
		if (this.plainTextEditMode) {
			switch (menuItem.tag) {
				case 'spellVariants':
					spanEl.dom.innerHTML = menuItem.hint;
					spanEl.setStyle('background', 'none');
					spanEl.removeAllListeners();
					break;
				case 'editWord':
					this.editErrorSpan(spanEl);
					break;
			}
		} else {
			spanEl.$.innerHTML = menuItem.hint;
			spanEl.setStyle('background', 'none');
			spanEl.removeAllListeners();
		}
	},

	setSize: function(w, h) {
		w = this.processSizeUnit(w);
		h = this.processSizeUnit(h);
		Terrasoft.HtmlEdit.superclass.setSize.call(this, w, h);
		if (h == undefined || !this.rendered) {
			return;
		}
		var wrapFrameWidth = this.wrap.getFrameWidth('tb');
		var elHeight = h - wrapFrameWidth - (this.toolbarVisible ? this.toolbar.getHeight() : 0);
		elHeight = elHeight < 0 ? 0 : elHeight;
		/*
		this.wrap.setHeight(elHeight);
		this.el.setHeight(elHeight);
		*/
		this.wrap.setHeight(h);
		this.elWrap.setHeight(elHeight);
		if (!this.designMode) {
			this.spellingEl.setHeight(elHeight);
			this.el.setHeight(elHeight);
		}
	},

	getActionEl: function() {
		return this.wrap;
	},

	createSpellingEl: function() {
		// TODO добавить нормальные стили
		var spellingElStyle = 'width: 100%; height: 100%; font-family: \'Courier New\' , \'Monospace\'; padding: 0px;';
		spellingElStyle += 'font-size: small; background-color: #fff; \'white-space\': pre-wrap; border: 0px;';
		spellingElStyle += 'text-align: left; padding-right: 0px; overflow-y: auto; display: none';
		var spellingEl = this.spellingEl = Ext.DomHelper.append(this.wrap, {
				tag: 'div',
				style: spellingElStyle
			},
			true
		);
		spellingEl.htmlEdit = this;
		spellingEl.dom.spellcheck = false;
		spellingEl.on('contextmenu', function(event) {
			event.stopEvent();
		}, this);
		return spellingEl;
	},

	getErrorByNumber: function(errNumber) {
		var errors = this.spellErrors;
		if (!errors) {
			return null;
		}
		for (var i = 0; i < errors.length; i++) {
			var error = errors[i];
			if (error.errorNumber == errNumber) {
				return error;
			}
		}
		return null;
	},

	onCkEditorReady: function() {
		this.ckEditorInitialized = true;
		var ckEditor = this.ckEditor;
		var enabled = this.startEnabled != undefined ? this.startEnabled : this.enabled;
		this.setEnabled(enabled);
		delete this.startEnabled;
		this.actualizeEditorToolbarButtons();
		if (ckEditor.getMode().name == 'source') {
			ckEditor.textarea.$.id = this.id + '_sourceText';
			ckEditor.textarea.$.name = this.id + '_sourceText';
			ckEditor.textarea.$.spellcheck = false;
		}
		this.reinitializeTools();
		var toolItems = this.toolbar.items;
		for (var i = 0, itemsLength = toolItems.length; i < itemsLength; i++) {
			var item = toolItems.itemAt(i);
			if (item.itemId != 'sourceedit') {
				item.enable();
			}
		}
		this.actualizeToolbar();
		if (Ext.isGecko) {
			this.fixGeckoImageAsDataUriPasting();
		}
	},

	fixGeckoImageAsDataUriPasting: function() {
		this.ckEditor.on('paste', function(event) {
			var data = event.data, html = data && data.html;
			if (html) {
				data.html = html.replace(/<img.*?src="data:image.*?>/g, "");
			}
		}, this);
		this.ckEditor.on('dataReady', function() {
			var ckDocument = this.ckEditor.document;
			ckDocument && ckDocument.$.addEventListener('drop', function(event) {
				event.preventDefault();
				event.stopPropagation();
			}, true);
		}, this);
	},

	reinitializeTools: function() {
		var toolbar = this.getToolbar();
		var ckEditorStyles = this.ckEditorStyles = this.getCkEditorStyles();
		for (var i = 0, toolsLength = toolbar.items.length; i < toolsLength; i++) {
			var toolItem = toolbar.items.itemAt(i);
			if (toolItem.getXType() == 'tsbutton') {
				this.subscribeToolButton(toolItem);
			}
			if (toolItem.getXType() == 'combo') {
				this.reinitComboboxStore(toolItem, ckEditorStyles[toolItem.styleName]);
			}
		}
		if (!this.designMode && this.ckEditorInitialized) {
			if (this.fontNameSelectionVisible) {
				var fontFamiliesComboBox = toolbar['combobox-font'];
				fontFamiliesComboBox.setValue(fontFamiliesComboBox.defaultValue);
			}
			if (this.fontSizeSelectionVisible) {
				var fontSizeComboBox = toolbar['combobox-fontSize'];
				fontSizeComboBox.setValue(fontSizeComboBox.defaultValue);
			}
			if (this.formatSelectionVisible) {
				var formattingComboBox = toolbar['combobox-format'];
				formattingComboBox.setValue(formattingComboBox.defaultValue);
			}
		}
	},

	initCkEditor: function() {
		if (this.ckEditorLoaded !== true) {
			return;
		}
		if (this.rendered !== true) {
			return;
		}
		if (!this.designMode) {
			var el = this.el;
			var ckEditorConfig = this.ckEditorConfig;
			ckEditorConfig.startupMode = (this.mode.toLowerCase() == 'formatedtexteditmode' ? 'wysiwyg' : 'source');
			var ckEditor = this.ckEditor = CKEDITOR.replace(el.dom, ckEditorConfig);
			ckEditor.mode = ckEditorConfig.startupMode;
			ckEditor.on('focus', this.onFocus, this);
			ckEditor.on('instanceReady', this.onCkEditorReady, this);
			ckEditor.on('afterCommandExec', this.onCkEditorCommandExec, this);
			ckEditor.on('beforeCommandExec', this.onBeforeCkEditorCommandExec, this);
		}
	},

	onRender: function(ct, position) {
		Terrasoft.HtmlEdit.superclass.onRender.call(this, ct, position);
		var el = this.el;
		if (this.designMode) {
			el.setStyle('display', 'none');
		}
		this.elWrap = el.wrap({
			cls: 'x-html-editor-wrap',
			width: '100%',
			height: '100%'
		});
		this.wrap = this.elWrap.wrap({
			cls: 'x-form-textarea-wrap',
			cn: {
				cls: 'x-html-editor-tb'
			}
		});
		var editModeHiddenField = this.editModeHiddenField = this.el.insertSibling({
			tag: 'input',
			type: 'hidden',
			name: this.id + '_editMode',
			id: this.id + '_editMode'
		}, 'before', true);
		this.el.dom.value = this.text || '';
		this.setEditorMode(this.mode);
		editModeHiddenField.value = this.getEditorMode();
		this.initCkEditor();
		this.createToolbar();
		if (!this.toolbarVisible) {
			this.toolbar.setVisible(false);
		}
		this.actualizeToolbar();
		this.startValue = this.value = this.text || '';
		if (!this.designMode) {
			this.createSpellingEl();
		}
		if (this.edges) {
			this.setEdges(this.edges);
		}
		this.activated = true;
	},

	disableTools: function() {
		var toolItems = this.toolbar.items;
		for (var i = 0, itemsLength = toolItems.length; i < itemsLength; i++) {
			var item = toolItems.itemAt(i);
			item.setEnabled(false);
		}
	},

	onCkEditorCommandExec: function(event) {
		var commandName = event.data.name;
		switch (commandName) {
			case 'source':
				var htmlEditor = this;
				setTimeout(function() {
					htmlEditor.actualizeToolbar();
					if (htmlEditor.wrap.hasClass(htmlEditor.invalidClass)) {
						htmlEditor.markInvalid();
					}
				}, 100);
				break;
			default:
				break;
		}
	},

	onBeforeCkEditorCommandExec: function(event) {
		var commandName = event.data.name;
		switch (commandName) {
			case 'source':
				this.disableTools();
				break;
			default:
				break;
		}
	},

	onCkEditorBlur: function(event) {
		this.ckEditor.removeListener('blur', this.onCkEditorBlur);
		var focusedControl = Terrasoft.FocusManager.getFocusedControl();
		if (focusedControl) {
			if (focusedControl.isHtmlEditTool) {
				this.onFocus();
			}
		}
	},

	unFocus: function() {
		if (this.designMode || !this.ckEditorInitialized) {
			return;
		}
		Ext.get(Ext.isIE ? document.body : document).un("mousedown", this.checkFocus, this);
		this.hasFocus = false;
		this.ckEditor.updateElement();
		var value = this.el.dom.value;
		var startValue = this.startValue;
		if (this.validateOnBlur === true) {
			this.validate(true);
		}
		if (value != startValue) {
			this.fireChangeEvent(value, startValue, false);
			this.startValue = value;
		}
		this.fireEvent("blur", this);
	},

	checkFocus: function(event) {
		if (this.wrap.contains(event.target)) {
			this.onFocus.defer(5, this);
		} else {
			this.unFocus();
		}
	},

	onFocus: function() {
		if (this.designMode || !this.ckEditorInitialized) {
			return;
		}
		if (this.hasFocus) {
			return;
		}
		if (this.focusClass) {
			this.el.addClass(this.focusClass);
		}
		Ext.get(Ext.isIE ? document.body : document).on("mousedown", this.checkFocus, this);
		if (!this.hasFocus) {
			this.hasFocus = true;
			Terrasoft.FocusManager.setFocusedControl.defer(10, this, [this]);
			this.fireEvent("focus", this);
		}
		var ckEditor = this.ckEditor;
		ckEditor.on('blur', this.onCkEditorBlur, this);
		ckEditor.focus();
		if (this.validationEvent !== false) {
			ckEditor.on('key', this.onCkEditorKeyPressed, this);
		}
	},

	onCkEditorKeyPressed: function() {
		this.validateAndRemoveListener.defer(10, this);
	},

	validateAndRemoveListener: function(ckEvent) {
		this.validate();
		if (!Ext.isEmpty(this.startValue)) {
			this.ckEditor.removeListener('key', this.onCkEditorKeyPressed);
		}
	},

	onResize: function(w, h) {
		Terrasoft.HtmlEdit.superclass.onResize.apply(this, arguments);
		if (this.el) {
			if (typeof w == 'number') {
				var elBorderWidth = this.wrap.getFrameWidth('lr');
				var resultWidth = w - elBorderWidth > 0 ? w - elBorderWidth : 0;
				this.toolbar.setWidth(resultWidth);
			}
			if (typeof h == 'number') {
				var toolbarHeight = this.toolbarVisible ? this.toolbar.getHeight() : 0;
				var resultHeight = h - this.wrap.getFrameWidth('tb') - toolbarHeight;
				if (resultHeight < 0) {
					resultHeight = 0;
				}
				this.el.setHeight(resultHeight);
			}
		}
	},

	getEditorMode: function() {
		if (this.spellMode) {
			return 'spellMode';
		}
		if (this.plainTextEditMode) {
			return 'plainTextEditMode';
		} else if (this.sourceEditMode) {
			return 'sourceEditMode';
		} else {
			return 'formatedTextEditMode';
		}
	},

	actualizeToolbar: function() {
		var editorMode = this.getEditorMode();
		var editorEnabled = this.enabled;
		var toolItems = this.toolbar.items;
		for (var i = 0, itemsLength = toolItems.length; i < itemsLength; i++) {
			var item = toolItems.itemAt(i);
			if (!item.enabledEditModes) {
				continue;
			}
			var itemEnabled = !editorEnabled ? false : item.enabledEditModes[editorMode];
			item.setEnabled(itemEnabled);
		}
	},

	setEditorMode: function(currentEditorModeName) {
		var availableModes = this.availableEditordModes;
		for (var i = 0; i < availableModes.length; i++) {
			var modeName = availableModes[i];
			this[modeName] = modeName.toLowerCase() == currentEditorModeName.toLowerCase();
		}
	},

	actualizeEditorToolbarButtons: function() {
		var editorMode = this.getEditorMode();
		switch (editorMode) {
			case 'formatedTextEditMode':
				this.toolbar['formatedText'].toggle(true);
				break;
			case 'plainTextEditMode':
				this.toolbar['plaintext'].toggle(true);
				break;
			case 'sourceEditMode':
				this.toolbar['source'].toggle(true);
				break;
		}
	},

	toggleEditorMode: function(targetModeName) {
		var currentModeLowerCase = this.getEditorMode().toLowerCase();
		var targetModeNameLowerCase = targetModeName.toLowerCase();
		if (targetModeNameLowerCase == currentModeLowerCase) {
			return;
		}
		this.mode = targetModeName;
		this.setEditorMode(targetModeName);
		var isTargetPlainTextMode = targetModeNameLowerCase == 'plaintexteditmode';
		var isTargetFormattedTextMode = targetModeNameLowerCase == 'formatedtexteditmode';
		if (!this.ckEditorInitialized) {
			this.ckEditorConfig.startupMode =
				(isTargetFormattedTextMode ? 'wysiwyg' : 'source');
			return;
		}
		this.actualizeToolbar();
		var ckEditor = this.ckEditor;
		var plainText;
		var htmlEdit = this;
		var fireEvent = true;

		function fireEditModeChangeEvent() {
			ckEditor.updateElement();
			ckEditor.focus();
			htmlEdit.fireEvent('editmodechange', targetModeName);
		}

		switch (currentModeLowerCase) {
			case 'plaintexteditmode':
				if (isTargetFormattedTextMode) {
					fireEvent = false;
					plainText = ckEditor.getData();
					ckEditor.setData('');
					ckEditor.on('dataReady', function(event) {
						event.removeListener();
						var encodedPlainText = Ext.util.Format.htmlEncode(plainText);
						ckEditor.setData(
							'<div>' + encodedPlainText.replace(/\n*$/, '').replace(/\n/g, '</div><div>') + '</div>');
						ckEditor.on('dataReady', function(event) {
							event.removeListener();
							fireEditModeChangeEvent();
						});
					});
					ckEditor.execCommand('source');
				}
				break;
			case 'sourceeditmode':
				if (isTargetPlainTextMode) {
					plainText = ckEditor.getData();
					plainText = this.removeHtmlTags(plainText);
					ckEditor.setData(plainText);
				}
				if (isTargetFormattedTextMode) {
					ckEditor.execCommand('source');
				}
				break;
			case 'formatedtexteditmode':
				var id = this.id + '_sourceText';
				if (isTargetPlainTextMode) {
					fireEvent = false;
					plainText = ckEditor.getData();
					plainText = this.removeHtmlTags(plainText);
					ckEditor.setData('', function() {
						this.on('dataReady', setText, this);
						this.execCommand('source');
					});

					function setText(event) {
						event.removeListener();
						this.textarea.$.id = id;
						this.textarea.$.name = id;
						this.textarea.$.spellcheck = false;
						this.setData(plainText, fireEditModeChangeEvent);
					}
				} else {
					ckEditor.execCommand('source');
					ckEditor.textarea.$.id = id;
					ckEditor.textarea.$.name = id;
				}
				break;
		}
		this.editModeHiddenField.value = targetModeName;

		if (fireEvent) {
			fireEditModeChangeEvent();
		}
	},

	removeHtmlTags: function(value) {
		value = value.replace(/\t/gi, '');
		value = value.replace(/>\s+</gi, '><');
		// TODO: Хак для CR149873.
		// Проверить возможность убрать при переходе на следующую версию CKEditor
		if (Ext.isWebKit) {
			value = value.replace(/<div>(<div>)+/gi, '<div>');
			value = value.replace(/<\/div>(<\/div>)+/gi, '<\/div>');
		}
		value = value.replace(/<p>\n/gi, '');
		value = value.replace(/<div>\n/gi, '');
		value = value.replace(/<br[\s\/]*>\n?|<\/p>|<\/div>/gi, '\n');
		value = value.replace(/<[^>]+>|<\/\w+>/gi, '');
		value = value.replace(/&nbsp;/gi, " ");
		value = value.replace(/&amp;/gi, "&");
		value = value.replace(/&bull;/gi, " * ");
		value = value.replace(/&ndash;/gi, "-");
		value = value.replace(/&quot;/gi, "\"");
		value = value.replace(/&laquo;/gi, "\"");
		value = value.replace(/&raquo;/gi, "\"");
		value = value.replace(/&lsaquo;/gi, "<");
		value = value.replace(/&rsaquo;/gi, ">");
		value = value.replace(/&trade;/gi, "(tm)");
		value = value.replace(/&frasl;/gi, "/");
		value = value.replace(/&lt;/gi, "<");
		value = value.replace(/&gt;/gi, ">");
		value = value.replace(/&copy;/gi, "(c)");
		value = value.replace(/&reg;/gi, "(r)");
		value = value.replace(/\n*$/, '');
		return value;
	},

	showCreateImageWindow: function() {
		var value = {
			source: 'None',
			curSchemaUId: '',
			schemaUId: '',
			itemUId: '',
			imageListUId: '',
			imageUId: '',
			resourceManagerName: '',
			resourceItemName: '',
			url: '',
			resourceName: '',
			entityPrimaryColumnValue: '',
			entitySchemaColumnUId: '',
			usePrimaryImageColumn: true
		};
		var availableControlImageSources = [
			'Image',
			'ImageListSchema',
			'Url'
		];
		var getDataMethods = {
			ImageListSchema_SchemaUId: 'GetImageListSchema',
			ImageListSchema_ItemUId: 'GetImageListSchemaItem'
			//ImageList_ImageListUId: 'GetImageList',
			//ImageList_ImageUId: 'GetImageListItem',
			//ResourceManager_ResMngr: 'GetResourceManegerName',
			//ResourceManager_ResItem: 'GetResourceItemName',
		};
		var filters = [];
		var dataService = 'Services/DataService';
		var ckEditor = this.ckEditor;
		var htmlEdit = this;
		Terrasoft.ControlImageEditWindow.showEditWindow({
			fileUploadControlId: this.id + '_loadedImage',
			value: value,
			filters: filters,
			dataService: dataService,
			getDataMethods: getDataMethods,
			availableControlImageSources: availableControlImageSources,
			okButtonClickHandler: function(controlImage) {
				if (controlImage.source == 'Image') {
					htmlEdit.fireEvent('imageloaded', htmlEdit);
					Terrasoft.ControlImageEditWindow.closeWindow();
					return;
				}
				htmlEdit.insertImage(controlImage);
				Terrasoft.ControlImageEditWindow.closeWindow();
				ckEditor.focus();
			},
			cancelButtonClickHandler: function() {
				Terrasoft.ControlImageEditWindow.closeWindow();
			}
		});
	},

	insertImage: function(controlImageValue) {
		if (!this.ckEditorInitialized) {
			return;
		}
		var ckEditor = this.ckEditor;
		controlImageValue.notWrap = true;
		var imageUrl = this.getImageSrc(controlImageValue);
		var imageElement = ckEditor.document.createElement('img');
		imageElement.setAttribute('alt', '');
		imageElement.setAttribute('src', imageUrl);
		ckEditor.insertElement(imageElement);
	},

	createLink: function() {
		var url = prompt(this.createLinkText, this.defaultLinkValue);
		var editor = this.ckEditor;
		if (url && url != 'http:/' + '/') {
			this.focus();
			var attributes = {};
			attributes.href = url;
			attributes['data-cke-saved-href'] = url;
			var editorDocument = editor.document;
			var selection = editor.getSelection();
			var element = selection.getStartElement();
			if (element.$.tagName === 'A') {
				element.setAttributes(attributes);
			} else {
				var ranges = selection.getRanges(true);
				if (ranges.length == 1 && ranges[0].collapsed) {
					var text = new CKEDITOR.dom.text(attributes['data-cke-saved-href'], editorDocument);
					ranges[0].insertNode(text);
					ranges[0].selectNodeContents(text);
					selection.selectRanges(ranges);
				}
				var style = new CKEDITOR.style({
					element: 'a',
					attributes: attributes
				});
				style.type = CKEDITOR.STYLE_INLINE;
				style.apply(editorDocument);
			}
		}
		editor.updateElement();
		editor.focus();
	},

	getResizeEl: function() {
		return this.wrap;
	},

	getPositionEl: function() {
		return this.wrap;
	},

	initEvents: function() {
	},

	focus: function() {
		var ckEeditor = this.ckEditor;
		if (ckEeditor) {
			ckEeditor.focus();
		}
	},

	onDestroy: function() {
		if (this.rendered) {
			this.toolbar.items.each(function(item) {
				if (item.menu) {
					item.menu.removeAll();
					if (item.menu.el) {
						item.menu.el.destroy();
					}
				}
				item.destroy();
			});
			this.ckEditor && this.ckEditor.destroy();
			this.wrap.dom.innerHTML = '';
			this.elWrap.dom.innerHTML = '';
			this.wrap.remove();
			this.elWrap.remove();
			var menu = this.menu;
			if (menu) {
				menu.destroy();
			}
		}
	},

	executeCommand: function(btn) {
		if (this.designMode) {
			return;
		}
		if (!this.activated) {
			return;
		}
		var command = btn.commandName;
		if (command == 'forecolor' || command == 'backcolor') {
			return;
		}
		var ckEditor = this.ckEditor;
		ckEditor.focus();
		ckEditor.execCommand(command);
		ckEditor.updateElement();
	},

	getRawValue: function() {
		var v;
		if (!this.rendered) {
			v = Ext.value(this.value, '');
		} else {
			var ckEditor = this.ckEditor;
			if (ckEditor && this.ckEditorInitialized) {
				ckEditor.updateElement();
				v = this.el.dom.value;
			} else {
				v = this.el.dom.value || '';
			}
		}
		if (v === this.emptyText) {
			v = '';
		}
		var browserInfo = Terrasoft.getBrowser();
		if (browserInfo.browserName === 'Firefox' && browserInfo.version < 4.0) {
			v = this.replaceRgbColorFormat(v);
		}
		return v;
	},

	replaceRgbColorFormat: function(value) {
		var browserInfo = Terrasoft.getBrowser();
		if (browserInfo.browserName !== 'Firefox' || browserInfo.version >= 4.0) {
			return value;
		}
		value = value.replace(/rgb\s*\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*\)/ig,
			function(matchString, redString, greenString, blueString, position, s) {
				var red = parseInt(redString);
				var green = parseInt(greenString);
				var blue = parseInt(blueString);
				red = red == 0 ? '00' : red.toString(16);
				green = green == 0 ? '00' : green.toString(16);
				blue = blue == 0 ? '00' : blue.toString(16);
				red = red.length == 1 ? red + red : red;
				green = green.length == 1 ? green + green : green;
				blue = blue.length == 1 ? blue + blue : blue;
				return '#' + red + green + blue;
			}
		);
		return value;
	},

	getValue: function() {
		return this.getRawValue();
	},

	setValue: function(value, isInitByEvent) {
		var oldValue = this.startValue || '';
		Terrasoft.HtmlEdit.superclass.setValue.call(this, value);
		value = value || "";
		if (value != oldValue) {
			var ckEditor = this.ckEditor;
			this.value = value;
			ckEditor && ckEditor.setData(value);
			this.fireChangeEvent(value, oldValue, isInitByEvent);
			this.startValue = value;
			this.oldValue = value;
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

	getToolbar: function() {
		return this.toolbar;
	},

	getCursorPosition: function() {
		if (this.ckEditorInitialized !== true) {
			return 0;
		}
		var position = 0;
		var ckEditor = this.ckEditor;
		var mode = ckEditor.getMode().name;
		if (mode != 'source') {
			return 0;
		}
		var el = ckEditor.textarea.$;
		if (el.selectionStart || el.selectionStart == '0') {
			position = el.selectionStart;
		}
		return position;
	},

	setCursorPosition: function(position) {
		if (this.ckEditorInitialized !== true) {
			return;
		}
		var ckEditor = this.ckEditor;
		var mode = ckEditor.getMode().name;
		if (mode != 'source') {
			return;
		}
		var el = ckEditor.textarea.$;
		if (el.setSelectionRange) {
			el.setSelectionRange(position, position);
		} else if (el.createTextRange) {
			var range = el.createTextRange();
			range.collapse(true);
			range.moveEnd('character', position);
			range.moveStart('character', position);
			range.select();
		}
	},

	insertTextInSourceMode: function(text, position) {
		if (this.ckEditorInitialized !== true) {
			return;
		}
		var ckEditor = this.ckEditor;
		var mode = ckEditor.getMode().name;
		if (mode != 'source') {
			return;
		}
		if (position === null || position === undefined) {
			position = this.getCursorPosition();
		} else {
			this.setCursorPosition(position);
		}
		if (document.selection) {
			var range = document.selection.createRange();
			range.text = text;
			range.select();
		} else {
			var elDom = ckEditor.textarea.$;
			var value = elDom.value;
			var startIndex = elDom.selectionStart || 0;
			var endIndex = elDom.selectionEnd || value.length;
			if (elDom.selectionEnd == 0) {
				endIndex = 0;
			}
			var firstValue = value.substring(0, startIndex);
			var lastValue = value.substring(endIndex);
			elDom.value = firstValue + text + lastValue;
			elDom.selectionStart = startIndex + 1;
			elDom.selectionEnd = startIndex + 1;
		}
	},

	insertTextInFormatTextMode: function(text, position) {
		if (this.ckEditorInitialized !== true) {
			return;
		}
		var ckEditor = this.ckEditor;
		var mode = ckEditor.getMode().name;
		var el = null;
		if (mode != 'wysiwyg') {
			return;
		}
		if (position === null || position === undefined) {
			setTimeout(function() {
				ckEditor.fire('paste', {'text': text});
			}, 50);
		} else {
			el = ckEditor.document.$.body;
			// TODO : найти более оптимальный способ вставки текста в произвольную позицию
			// в режиме отображения форматируемого текста
			var pasteInformation = {
				currentPosition: 0,
				position: position,
				text: text
			};

			function insertText(el, pasteInformation) {
				var textInserted = false;
				for (var i = 0; i < el.childNodes.length; i++) {
					var node = el.childNodes[i];
					if (node.childNodes.length) {
						textInserted = insertText(node, pasteInformation);
						if (textInserted) {
							return textInserted;
						}
					} else {
						if (!node.nodeValue) {
							continue;
						}
						if (node.nodeValue.length + pasteInformation.currentPosition >= pasteInformation.position) {
							var beforeText =
								node.nodeValue.substring(0,
									pasteInformation.position - pasteInformation.currentPosition);
							var afterText =
								node.nodeValue.substring(pasteInformation.position - pasteInformation.currentPosition);
							node.nodeValue = beforeText + pasteInformation.text + afterText;
							return true;
						} else {
							pasteInformation.currentPosition += node.nodeValue.length;
							continue;
						}
					}
				}
				return false;
			}

			insertText(el, pasteInformation);
		}
	},

	insertTextAsSourceInFormatTextMode: function(text, position) {
		if (this.ckEditorInitialized !== true) {
			return;
		}
		var ckEditor = this.ckEditor;
		var mode = ckEditor.getMode().name;
		var el = null;
		if (mode != 'wysiwyg') {
			return;
		}
		if (position === null || position === undefined) {
			setTimeout(function() {
				ckEditor.fire('paste', {'html': text});
			}, 50);
		} else {
			el = ckEditor.document.$.body;
			// TODO : найти более оптимальный способ вставки текста в произвольную позицию
			// в режиме отображения форматируемого текста
			var pasteInformation = {
				currentPosition: 0,
				position: position,
				text: text
			};

			function insertText(el, pasteInformation) {
				var textInserted = false;
				for (var i = 0; i < el.childNodes.length; i++) {
					var node = el.childNodes[i];
					if (node.childNodes.length) {
						textInserted = insertText(node, pasteInformation);
						if (textInserted) {
							return textInserted;
						}
					} else {
						if (!node.nodeValue) {
							continue;
						}
						if (node.nodeValue.length + pasteInformation.currentPosition >= pasteInformation.position) {
							var beforeText =
								node.nodeValue.substring(0,
									pasteInformation.position - pasteInformation.currentPosition);
							var afterText =
								node.nodeValue.substring(pasteInformation.position - pasteInformation.currentPosition);
							node.nodeValue = beforeText + pasteInformation.text + afterText;
							return true;
						} else {
							pasteInformation.currentPosition += node.nodeValue.length;
							continue;
						}
					}
				}
				return false;
			}

			insertText(el, pasteInformation);
		}
	},

	insertTextBeforeRender: function(text, position) {
		if (this.rendered) {
			return;
		}
		var value = this.value || '';
		if (!position) {
			value = value + text;
		} else {
			if (value.length >= position) {
				value = value + text;
			} else if (value.length == 0 || position <= 0) {
				value = text + value;
			} else {
				value = value.substring(0, position) + text + value.substring(position);
			}
		}
		this.value = value;
	},

	insertTextAsSource: function(text, position) {
		if (!this.rendered || !this.ckEditorInitialized) {
			this.insertTextBeforeRender(text, position);
			return;
		}
		var ckEditor = this.ckEditor;
		var mode = ckEditor.getMode().name;
		ckEditor.focus();
		switch (mode) {
			case 'wysiwyg':
				this.insertTextAsSourceInFormatTextMode(text, position);
				break;
			case 'source':
				this.insertText(text, position);
				break;
		}
	},

	insertText: function(text, position) {
		if (!this.rendered || !this.ckEditorInitialized) {
			this.insertTextBeforeRender(text, position);
			return;
		}
		var ckEditor = this.ckEditor;
		var mode = ckEditor.getMode().name;
		ckEditor.focus();
		switch (mode) {
			case 'wysiwyg':
				this.insertTextInFormatTextMode(text, position);
				break;
			case 'source':
				this.insertTextInSourceMode(text, position);
				break;
		}
	},

	isSetDefaultSpellChecker: function() {
		return typeof Terrasoft.defaultSpellChecker == "function";
	},

	isSpellTextButtonVisible: function() {
		return this.spellTextButtonVisible && this.isSetDefaultSpellChecker();
	}
});

Ext.reg('htmledit', Terrasoft.HtmlEdit);

Terrasoft.SpellChecker = function(config) {
	Ext.apply(this, config);
};

Ext.extend(Terrasoft.SpellChecker, Ext.util.Observable, {
	isProviderInitialized: false,
	spellerOptions: null,
	verifiableLanguages: {},
	currentLanguage: '',
	webService: '',
	webMethod: '',
	parametersOrder: [],
	requestParameters: [],
	verifiableTextParameterName: '',
	languageParameterName: '',
	optionsParameterName: '',
	formatParameterName: '',
	maxTextLength: Ext.isIE ? 200 : 1500,
	textParts: [],
	spellCheckers: [],
	spellResult: [],
	//requestMethod

	initComponent: function() {
		this.id = Ext.id();
		this.addEvents(
			'textspelled'
		);
	},

	getSpellChecker: function(index) {
		//var spellChecker = new Terrasoft.YandexSpellChecker();
		var spellChecker = new Terrasoft.defaultSpellChecker();
		spellChecker.initComponent();
		spellChecker.index = index;
		return spellChecker;
	},

	sliceText: function(text) {
		var textParts = [];
		var maxTextLength = this.maxTextLength;
		while (text.length > maxTextLength) {
			var position = 0;
			var regex = new RegExp(/(\<\/?[^\>]+\>)|((?![\b\s])[^\s\n\t\r\<\>]+(?![\b\s])?)/gi);
			var iterationCounter = 0;
			while (true) {
				if (iterationCounter >= 10000) {
					throw 'recursive call';
				}
				iterationCounter++;
				regex.exec(text);
				if (regex.lastIndex >= maxTextLength) {
					var part = text.substring(0, position);
					textParts.push(part);
					text = text.substring(position);
					break;
				}
				position = regex.lastIndex;
			}
		}
		textParts.push(text);
		return textParts;
	},

	onSpellCheckerTextChecked: function(spellChecker, result) {
		var spellResult = this.spellResult;
		var errorsCount = result.length;
		for (var i = 0; i < errorsCount; i++) {
			var error = result[i];
			spellResult.push({
				errorNumber: spellResult.length,
				errorCode: error.errorCode,
				errorCaption: error.errorCaption,
				wordPosition: this.getWordPosition(error.wordPosition, spellChecker.index),
				wrodLength: error.wrodLength,
				originalWord: error.originalWord,
				hints: error.hints
			});
		}
		spellChecker.finished = true;
		//var spellCheckers = this.spellCheckers;
		//spellCheckers.destroy();
		if (this.hasSpellCheckers()) {
			this.onTextSpelled();
		}
	},

	getWordPosition: function(wordPosition, spellerIndex) {
		var textParts = this.textParts;
		var position = wordPosition;
		for (var i = 0; i < spellerIndex; i++) {
			position += textParts[i].length * 1;
		}
		return position;
	},

	hasSpellCheckers: function() {
		var spellCheckers = this.spellCheckers;
		for (var i = 0; i < spellCheckers.length; i++) {
			var spellChecker = spellCheckers[i].speller;
			if (spellChecker.finished === undefined) {
				return false;
			}
			if (spellChecker.finished !== true) {
				return false;
			}
		}
		return true;
	},

	onTextSpelled: function() {
		var spellCheckers = this.spellCheckers;
		for (var i = 0; i < spellCheckers.length; i++) {
			spellCheckers[i].speller.un('textchecked', this.onSpellCheckerTextChecked, this);
		}
		this.fireEvent('textspelled', this, this.spellResult);
		this.spellResult = [];
		this.textParts = [];
		this.spellCheckers = [];
	},

	spell: function(text, options) {
		this.spellResult = [];
		var spellCheckers = this.spellCheckers = [];
		this.textParts = [];
		var textParts = this.textParts = Ext.isArray(text) ? text : this.sliceText(text);
		for (var i = 0; i < textParts.length; i++) {
			var part = textParts[i];
			var spellChecker = this.getSpellChecker(i);
			spellChecker.on('textchecked', this.onSpellCheckerTextChecked, this);
			spellCheckers.push({
				speller: spellChecker,
				text: part,
				textLength: part.length
			});
			spellChecker.checkText(part, options);
		}
	}
});

Terrasoft.BaseSpellChecker = function(config) {
	Ext.apply(this, config);
};

Ext.extend(Terrasoft.BaseSpellChecker, Ext.util.Observable, {
	isProviderInitialized: false,
	spellerOptions: null,
	verifiableLanguages: {},
	currentLanguage: '',
	webService: '',
	webMethod: '',
	parametersOrder: [],
	requestParameters: [],
	verifiableTextParameterName: '',
	languageParameterName: '',
	optionsParameterName: '',
	formatParameterName: '',
	//encodingParameterName: 'ie'//utf-8, 1251

	initComponent: function() {
		this.id = Ext.id();
		this.addEvents(
			'textchecked'
		);
	},

	onTextSpelled: function(args) {
		this.fireEvent('textchecked', this, args);
	},

	getSpellerOptions: function() {
	},

	getAvailableLanguages: function() {
	},

	getSpellerUrl: function() {
		return String.format('{0}/{1}', this.webService, this.webMethod);
	},

	applyOptions: function(text, options) {
	},

	spellText: function(url, spellerParameters) {
	},

	checkText: function(text, options) {
		this.applyOptions(text, options);
		var url = this.getSpellerUrl();
		var spellerParameters = this.getSpellerParameters();
		this.spellText(url, spellerParameters);
	},

	getParameter: function(index) {
		var requestParameters = this.requestParameters;
		for (var i = 0; i < requestParameters.length; i++) {
			var parameter = requestParameters[i];
			if (parameter.position == index) {
				return parameter;
			}
		}
		return null;
	},

	getSpellerParameters: function() {
		var params = [];
		var requestParameters = this.requestParameters;
		for (var i = 0; i < requestParameters.length; i++) {
			var parameter = this.getParameter(i);
			if (parameter == null) {
				continue;
			}
			var parameterValue = parameter.getValue();
			if (parameterValue == null || parameterValue == undefined) {
				continue;
			}
			if (i != 0) {
				params.push('&');
			}
			params.push(parameter.parmeterName + '=', parameterValue);
		}
		return params;
	}
});

Terrasoft.YandexSpellCheckerJsonpService = function() {
	var isBusy = false;
	var callbackFunction = null;
	var scope = null;
	var scriptNode = null;
	var yandexSpellCheckerUrl = 'http://speller.yandex.net/services/spellservice.json/checkText';

	function getScriptElId() {
		if (!scope.id) {
			return null;
		}
		return scope.id + '_JSONP';
	}

	function generateScriptNode(srcUrl) {
		var scriptId = getScriptElId();
		if (!scriptId || !srcUrl) {
			return false;
		}
		var head = document.getElementsByTagName("head")[0];
		scriptNode = document.createElement('script');
		scriptNode.id = getScriptElId();
		scriptNode.async = true;
		scriptNode.type = 'text/javascript';
		scriptNode.src = srcUrl;
		head.appendChild(scriptNode);
		return true;
	}

	function removeScriptNode(srcUrl) {
		if (!scriptNode) {
			return;
		}
		scriptNode.parentNode.removeChild(scriptNode);
		scriptNode = null;
	}

	return {
		requestData: function(scopeObject, urlParameters, callbackFunc) {
			// TODO придумать способ для параллельной проверки нескольких частей текста или нескольких текстов
			if (isBusy == true) {
				return false;
			}
			callbackFunction = callbackFunc;
			scope = scopeObject;
			isBusy = true;
			var jsonpFunction = 'callback=Terrasoft.YandexSpellCheckerJsonpService.jsonpHandler';
			if (urlParameters) {
				var scriptUrl = String.format('{0}?{1}&{2}', yandexSpellCheckerUrl, urlParameters, jsonpFunction);
			} else {
				var scriptUrl = String.format('{0}?{1}', yandexSpellCheckerUrl, jsonpFunction);
			}
			scriptUrl = String.format('{0}&t={1}', scriptUrl, Math.round(Math.random() * 1000000) + '3');
			return generateScriptNode(scriptUrl);
		},

		jsonpHandler: function(args) {
			var result = {
				spellResult: args
			};
			callbackFunction.defer(50, scope, [result]);
			removeScriptNode();
			callbackFunction = null;
			scope = null;
			isBusy = false;
		}
	};
}();

Terrasoft.YandexSpellChecker = Ext.extend(Terrasoft.BaseSpellChecker, {
	webService: 'http://speller.yandex.net/services/spellservice.json',
	webMethod: 'checkText',
	verifiableTextParameterName: 'text',
	languageParameterName: 'lang',
	optionsParameterName: 'options',
	formatParameterName: 'format',
	spellerOptions: {
		ignoreUppercase: true,
		ignoreDigits: true,
		ignoreUrls: true,
		findRepeatWorlds: true,
		ignoreLatin: false,
		noSuggest: false,
		flagLatin: true,
		byWorlds: false,
		ignoreCapitalization: false,
		format: 'plain'
	},
	availableFormats: ['html', 'plain'],
	currentLanguage: 'ru',

	getErrorCaption: function(errorCode) {
		var yandexErrorCodes = this.yandexErrorCodes;
		for (var propertyName in yandexErrorCodes) {
			if (yandexErrorCodes[propertyName] == errorCode) {
				return propertyName;
			}
		}
		return null;
	},

	onTextSpelled: function(args) {
		var result = args.spellResult;
		var errorsCount = result.length;
		var errors = [];
		for (var i = 0; i < errorsCount; i++) {
			var yndexError = result[i];
			errors.push({
				errorNumber: i,
				errorCode: yndexError.code,
				errorCaption: this.getErrorCaption(yndexError.code),
				wordPosition: yndexError.pos,
				rowNumber: yndexError.row,
				columnNumber: yndexError.col,
				wrodLength: yndexError.len,
				originalWord: yndexError.word,
				hints: yndexError.s
			});
		}
		Terrasoft.YandexSpellChecker.superclass.onTextSpelled.call(this, errors);
	},

	spellText: function(url, spellerParameters) {
		var parameters = spellerParameters.join('');
		this.spellTimeout(this, parameters);
	},

	spellTimeout: function(scope, parameters) {
		var result = Terrasoft.YandexSpellCheckerJsonpService.requestData(scope, parameters, scope.onTextSpelled);
		if (result == false) {
			setTimeout(function() {
				scope.spellTimeout(scope, parameters);
			}, 100);
		}
	},

	applyOptions: function(text, options) {
		var speller = this;
		var spellerOptions = this.spellerOptions;
		for (var propertyName in options) {
			spellerOptions[propertyName] = options[propertyName];
		}
		var requestParameters = this.requestParameters = [];
		var textParameter = {
			position: 0,
			parmeterName: this.verifiableTextParameterName,
			getValue: function() {
				return encodeURIComponent(text);
			}
		};
		requestParameters.push(textParameter);
		var languageParameter = {
			position: 1,
			parmeterName: this.languageParameterName,
			getValue: function() {
				if (options) {
					if (options.langs) {
						return options.langs || speller.currentLanguage;
					}
				}
				return speller.currentLanguage;
			}
		};
		requestParameters.push(languageParameter);
		var optionsParameter = {
			position: 2,
			parmeterName: this.optionsParameterName,
			getValue: function() {
				return speller.getOptions();
			}
		};
		requestParameters.push(optionsParameter);
		var formatParameter = {
			position: 3,
			parmeterName: this.formatParameterName,
			getValue: function() {
				return speller.getFormat();
			}
		};
		requestParameters.push(formatParameter);
	},

	getFormat: function() {
		return this.spellerOptions.format;
	},

	getOptions: function() {
		var optionsValue = 0;
		var yandexSpellChekerOptions = this.yandexSpellChekerOptions;
		var spellerOptions = this.spellerOptions;
		for (var propertyName in yandexSpellChekerOptions) {
			var option = spellerOptions[propertyName];
			if (option) {
				optionsValue += yandexSpellChekerOptions[propertyName];
			}
		}
		return optionsValue;
	},

	yandexSpellChekerOptions: {
		// Skip words in capital letters, such as "MIC".

		ignoreUppercase: 1,
		// Skip words with numbers, such as, "asd17x4534".

		ignoreDigits: 2,
		// Skip URLs, email addresses and file names.

		ignoreUrls: 4,
		// Highlight repetitions, such as, "I went to to Cyprus".

		findRepeatWorlds: 8,
		// Skip words in Latin characters, such as "madrid".

		ignoreLatin: 16,
		// Just check the text without giving out options for replacement.

		noSuggest: 32,
		// Mark words written in Latin, as errors.
		flagLatin: 128,
		// Do not use the context when checking.

		// The option is useful in cases when a list of individual words is transferred to the input of the service.

		byWorlds: 256,
		// Ignore incorrect use of UPPERCASE / lowercase letters, for example, in the word "washington".

		ignoreCapitalization: 512
	},

	yandexErrorCodes: {
		// The word is not in the dictionary.
		ERROR_UNKNOWN_WORD: 1,
		// Repetition.

		ERROR_REPEAT_WORD: 2,
		// Incorrect use of uppercase and lowercase letters.
		ERROR_CAPITALIZATION: 3,
		// The text contains too many errors.

		// In this case, the application can send Yandex.Speller the remaining unchecked text in the next request.
		ERROR_TOO_MANY_ERRORS: 4
	},

	getSpellerOptions: function() {
	}
});

(function() {
	Ext.apply(Terrasoft.HtmlEdit.prototype, {
		getFormatPainterStyles: function() {
			if (this.formatPainterStyles) {
				return this.formatPainterStyles;
			}
			var ckEditorConfig = this.ckEditorConfig;
			var defaults = this.ckDocumentDefaultCssProperties;
			var StyleConstructor = CKEDITOR.style;
			var styles = {
				basic: {
					bold: new StyleConstructor(ckEditorConfig.coreStyles_bold, {}),
					italic: new StyleConstructor(ckEditorConfig.coreStyles_italic, {}),
					underline: new StyleConstructor(ckEditorConfig.coreStyles_underline, {})
				},
				formatting: removeDefaultStyle(this.ckEditorStyles.formattingStyles.values,
					new StyleConstructor(ckEditorConfig.format_div)),
				fontFamily: removeDefaultStyle(this.ckEditorStyles.fontsStyles.values,
					new StyleConstructor(ckEditorConfig.font_style, {family: defaults.fontFamily})),
				fontSize: removeDefaultStyle(this.ckEditorStyles.fontsSizeStyles.values,
					new StyleConstructor(ckEditorConfig.fontSize_style, {size: defaults.fontSize})),
				foreColor: removeDefaultStyle(this.ckEditorStyles.foreColorStyles.values,
					new StyleConstructor(ckEditorConfig.colorButton_foreStyle, {color: defaults.color})),
				backColor: removeDefaultStyle(this.ckEditorStyles.backColorStyles.values,
					new StyleConstructor(ckEditorConfig.colorButton_backStyle, {color: defaults.backgroundColor}))
			};
			return this.formatPainterStyles = styles;
		},

		initFormatPainter: function() {
			var FORMAT_MODE = {
				none: 0,
				single: 1,
				multiple: 2
			};
			var mode = FORMAT_MODE.none;
			var button;

			function mouseUpHandler(event) {
				if (mode === FORMAT_MODE.none) {
					event.removeListener();
					return;
				}
				var ckEditor = this.ckEditor;
				var selection = ckEditor.document.getSelection();
				if (!selection) {
					return;
				}
				ckEditor.execCommand("removeFormat");
				var activeStyles = event.listenerData;
				for (var groupName in activeStyles) {
					if (activeStyles.hasOwnProperty(groupName)) {
						var group = activeStyles[groupName];
						for (var styleName in group) {
							if (group.hasOwnProperty(styleName)) {
								group[styleName].apply(ckEditor.document);
							}
						}
					}
				}
				if (mode != FORMAT_MODE.multiple) {
					mode = FORMAT_MODE.none;
					button.toggle(false);
					event.removeListener();
				}
				ckEditor.focus();
			}

			var doubleClickFlag = false;
			var doubleClickTimeout = 300;
			var doubleClickTimeoutId;

			function bindHandler() {
				if (doubleClickFlag) {
					doubleClickFlag = false;
				}
				button.toggle(true);
				var ckEditor = this.ckEditor;
				var selection = ckEditor.getSelection();
				var element = selection.getStartElement();
				var styles = this.getFormatPainterStyles();
				var activeStyles = {};
				var elementPath = new CKEDITOR.dom.elementPath(element);

				for (var groupName in styles) {
					if (styles.hasOwnProperty(groupName)) {
						var group = styles[groupName], isExclusive, activeStylesCount = 0, style, styleName;
						if (group.isExclusive) {
							isExclusive = true;
							delete group.isExclusive;
						}
						var activeGroup = activeStyles[groupName] = {};
						for (styleName in group) {
							if (group.hasOwnProperty(styleName)) {
								style = group[styleName];
								if (style.checkActive(elementPath)) {
									activeGroup[styleName] = style;
									activeStylesCount++;
								}
							}
						}
						if (isExclusive) {
							group.isExclusive = true;
						}
						if (activeStylesCount == 0) {
							delete activeStyles[groupName];
							continue;
						}
						if (activeStylesCount > 1 && isExclusive) {
							activeStyles[groupName] = removeFalseStyles(activeGroup, elementPath);
						}
					}
				}
				ckEditor.document.on('mouseup', mouseUpHandler, this, activeStyles);
			}

			return function(target) {
				button = target;
				switch (mode) {
					case FORMAT_MODE.none:
						doubleClickFlag = true;
						doubleClickTimeoutId = bindHandler.defer(doubleClickTimeout, this, [button]);
						mode = FORMAT_MODE.single;
						break;
					case FORMAT_MODE.single:
						if (doubleClickFlag) {
							doubleClickFlag = false;
							mode = FORMAT_MODE.multiple;
						} else {
							mode = FORMAT_MODE.none;
						}
						break;
					case FORMAT_MODE.multiple:
						doubleClickFlag = false;
						mode = FORMAT_MODE.none;
						button.toggle(false);
						break;
				}
				if (mode === FORMAT_MODE.none) {
					clearTimeout(doubleClickTimeoutId);
				}
			};
		}
	});

	function removeDefaultStyle(styleCollection, defaultStyle) {
		styleCollection = Ext.apply({}, styleCollection);
		var defaultStyleText = CKEDITOR.style.getStyleText(defaultStyle._.definition);
		for (var styleName in styleCollection) {
			if (styleCollection.hasOwnProperty(styleName)) {
				var style = styleCollection[styleName];
				var styleText = CKEDITOR.style.getStyleText(style._.definition);
				if (defaultStyleText === styleText) {
					delete styleCollection[styleName];
				}
			}
		}
		styleCollection.isExclusive = true;
		return styleCollection;
	}

	function removeFalseStyles(activeGroup, elementPath) {
		var elementsList = elementPath.elements.concat([]), parent;
		elementsList.shift();
		while (parent = elementsList.shift()) {
			var newPath = new CKEDITOR.dom.elementPath(parent);
			for (var styleName in activeGroup) {
				if (activeGroup.hasOwnProperty(styleName)) {
					var style = activeGroup[styleName];
					if (!style.checkActive(newPath)) {
						var newGroup = {};
						newGroup[styleName] = style;
						return newGroup;
					}
				}
			}
		}
		return {};
	}
})();