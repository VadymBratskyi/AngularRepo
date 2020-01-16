Terrasoft.Calculator = Ext.extend(Ext.LayoutControl, {
	number: '0',
	oldNumber: '0',
	num1: '',
	num2: '',
	operator: '',
	memValue: '0',
	addToNum: 'no',
	roundToInt: false,
	isFormField: true,

	initComponent: function() {
		Terrasoft.Calculator.superclass.initComponent.call(this);
		if (this.inputBoxID && typeof (this.inputBoxID) == "string") {
			var inputBox = Ext.getCmp(this.inputBoxID);
			if (inputBox && inputBox.getValue && inputBox.setValue) {
				this.inputBox = inputBox;
			}
		}
	},

	onRender: function(container, position) {
		var elCfg = {tag: 'div', id: this.id};
		if (!this.menu) {
			elCfg.tabIndex = 0;
		}
		this.el = container.createChild(elCfg);
		var stTableWidth = 195;
		if (!this.menu) {
			this.el.addClass("x-calc-wrap");
			this.el.dom.style.width = this.el.addUnits(stTableWidth);
			var elFrameWidth = this.el.getFrameWidth('lr');
			this.width = stTableWidth + elFrameWidth;
		} else {
			this.focusEl = this.el.createChild({
				tag: "a", cls: "x-menu-focus", href: "#", onclick: "return false;", tabIndex: "-1"
			});
			this.menu.focusEl = this.focusEl;
		}
		this.el.on('click', function() {this.focus();}, this);
		this.stTable = this.el.createChild({ 
				tag: 'table',
				cellspacing: 2,
				cellpadding: 0,
				width: stTableWidth,
				cls: 'x-calc-container'
			});
		var maxCols = 6;
		var stBtns =
		[
			[{ label: 'C', func: 'clear', keys: [27], colSpan: 2 },
				{ label: 'CE', func: 'clear', colSpan: 2 }, {}, {},
				{ label: 'BS', hidelabel: true, func: 'clear', style: 'x-calc-btn-backspace', keys: [22], 
					colSpan: 2 }, {}],
			[{ label: '7', func: 'enterDigit', keys: [55, 103] },
				{ label: '8', func: 'enterDigit', keys: [56, 104] },
				{ label: '9', func: 'enterDigit', keys: [57, 105] },
				{ label: '/', func: 'operation', keys: [111, 191] },
				{ label: '+/-', func: 'plusminus' }, { label: 'MC', func: 'memory'}],
			[{ label: '4', func: 'enterDigit', keys: [52, 100] },
				{ label: '5', func: 'enterDigit', keys: [53, 101] },
				{ label: '6', func: 'enterDigit', keys: [54, 102] },
				{ label: '*', overridelabel: 'x', func: 'operation', keys: [106] },
				{ label: '%', func: 'operation' }, { label: 'MR', func: 'memory'}],
			[{ label: '1', func: 'enterDigit', keys: [49, 97] }, 
				{ label: '2', func: 'enterDigit', keys: [50, 98] }, 
				{ label: '3', func: 'enterDigit', keys: [51, 99] }, 
				{ label: '-', func: 'operation', keys: [109] }, 
				{ label: '1/x', func: 'divisionToX' }, 
				{ label: 'MS', func: 'memory'}],
			[{ label: '0', func: 'enterDigit', keys: [48, 96] }, 
				{ label: '000', func: 'enterDigit' }, 
				{ label: '.', func: 'enterDot', keys: [110, 190] }, 
				{ label: '+', func: 'operation', keys: [107] }, 
				{ label: '=', func: 'equals', keys: [10, 13] }, 
				{ label: 'M+', func: 'memory'}]
		];
		var keyMap = this.getKeyMap();
		for (i = 0; i < stBtns.length; i++) {
			var btn = stBtns[i];
			var row = this.stTable.createChild({ tag: 'tr' });
			var rowChild = row.child('tr');
			if (rowChild != null) {
				row = rowChild;
			}
			for (j = 0; j < btn.length; j++) {
				if (btn[j].label == null) {
					continue;
				}
				var cell = Ext.get(row.dom.appendChild(document.createElement('td')));
				cell.dom.id = btn[j].id || Ext.id();
				if (btn[j].hidelabel == null) {
					cell.dom.innerHTML =
						(btn[j].overridelabel) ? btn[j].overridelabel : btn[j].label;
				}
				if (btn[j].colSpan) {
					cell.dom.setAttribute("colSpan", btn[j].colSpan);
				}
				cell.unselectable();
				switch (btn[j].func) {
					case 'enterDigit':
						var cls = 'x-calc-digit';
						break;
					case 'operation':
						var cls = 'x-calc-operator';
						break;
					case 'plusminus':
						var cls = 'x-calc-operator';
						break;
					case 'divisionToX':
						var cls = 'x-calc-operator';
						break;
					case 'equals':
						var cls = 'x-calc-equals';
						break;
					case 'clear':
						var cls = 'x-calc-memory';
						break;
					case 'memory':
						var cls = 'x-calc-memory';
						break;
				}
				cell.dom.className = cls;
				if (btn[j].label == 'BS') {
					var backspaceDiv = cell.createChild({ tag: 'div', id: Ext.id() });
					backspaceDiv.dom.innerHTML = '<br>';
					backspaceDiv.dom.className = btn[j].style;
				}
				if (j == btn.length - 1 && j < maxCols - 1) {
					cell.dom.colSpan = (maxCols - j + 1);
				}
				// TODO Включить поддержку ввода с цифровой клавиатуры когда определимся с клавишами
				/*if (btn[j].keys) {
					keyMap.addBinding({
						key: btn[j].keys,
						fn: this.onClick.createDelegate(this, [null, this, 
							{button: btn[j], viaKbd: true, cell: cell}]),
						scope: this
					});
				}*/
				cell.addClassOnOver('x-calc-btn-hover');
				cell.addClassOnClick('x-calc-btn-click');
				cell.on('click', this.onClick, this, { button: btn[j] });
			}
		}
		if (this.menu) {
			
			keyMap.addBinding([{
				key: Ext.EventObject.ESC,
				fn: this.onEscKeyDown,
				scope: this}, {
				key: Ext.EventObject.ENTER,
				fn: this.onEnterKeyDown,
				scope: this
			}]);
		}
	},

	getKeyMap: function() {
		if (!this.keyMap) {
			this.keyMap = new Ext.KeyMap(this.getFocusEl());
		}
		return this.keyMap;
	},

	onEscKeyDown: function() {
		if (this.inputBox && (this.inputBox.oldValue != undefined)) {
			this.inputBox.setValue(this.inputBox.oldValue);
		}
	},

	onEnterKeyDown: function(key, e) {
		this.menu.hide();
	},

	getFocusEl: function() {
		return this.focusEl || this.el;
	},

	setSize:Ext.emptyFn,

	getValue: function() {
		return (this.inputBox) ? this.inputBox.getValue() : null;
	},

	setValue: function(value) {
		this.number = value;
		if (this.inputBox) {
			this.inputBox.setValue(this.number);
		}
	},

	onClick: function(e, el, opt) {
		if (!this.enabled) {
			return;
		}
		var s = 'this.' + opt.button.func + '(\'' + opt.button.label + '\');';
		eval(s);
	},

	updateDisplay: function() {
		if (this.number == 'Infinity') {
			this.number = '0';
		}
		if (!this.inputBox) {
			return;
		}
		if (this.roundToInt) {
			this.number = String(Math.round(this.number));
		}
		if (!this.inputBox.readOnly){
			this.inputBox.setValue(this.number, undefined, false);
		}
	},

	enterDigit: function(n) {
		if (this.addToNum == 'yes') {
			this.number += n;
			if (this.number.charAt(0) == 0 && this.number.indexOf('.') == -1) {
				this.number = this.number.substring(1);
			}
		}
		else {
			if (this.addToNum == 'reset') {
				this.reset();
			}
			this.number = n;
			this.addToNum = 'yes';
		}
		this.updateDisplay();
	},

	enterDot: function() {
		if (this.addToNum == 'yes') {
			if (this.number.indexOf('.') != -1) {
				return;
			}
			this.number += '.';
		}
		else {
			if (this.addToNum == 'reset') {
				this.reset();
			}
			this.number = '0.';
			this.addToNum = 'yes';
		}
		this.updateDisplay();
	},

	plusminus: function() {
		if (this.number == '0') {
			return;
		}
		var newValue = (this.number.charAt(0) == '-') ? this.number.substring(1) : '-' + this.number;
		if (this.addToNum == 'reset') {
			this.num1 = newValue;
		}
		this.number = newValue;
		this.updateDisplay();
	},

	reset: function() {
		this.number = '0';
		this.addToNum = 'no';
		this.num1 = '';
		this.num2 = '';
		this.operator = '';
	},

	clear: function(o) {
		switch (o) {
			case 'C':
				this.clearAll();
				break;
			case 'CE':
				this.clearEntry();
				break;
			case 'BS':
				this.backspace();
				break;
			default:
				break;
		}
	},

	clearAll: function() {
		this.reset();
		this.updateDisplay();
	},

	clearEntry: function() {
		this.number = '0';
		this.addToNum = 'no';
		this.updateDisplay();
	},

	backspace: function() {
		var n = String(this.number);
		if (n == '0') {
			return;
		}
		var newValue = n.substring(0, n.length - 1);
		if (this.addToNum == 'reset') {
			this.num1 = newValue;
		}
		this.number = newValue;
		this.updateDisplay();
	},

	memory: function(o) {
		switch (o) {
			case 'M+':
				this.memStore(true);
				break;
			case 'MS':
				this.memStore();
				break;
			case 'MR':
				this.memRecall();
				break;
			case 'MC':
				this.memClear();
				break;
			default:
				break;
		}
	},

	memStore: function(add) {
		if (!this.number || this.number == '0') {
			return;
		}
		else {
			this.memValue = (add === true) ? this.calculate(this.number, this.memValue, '+') : this.number;
		}
	},

	memRecall: function() {
		if (this.memValue != '0') {
			this.number = this.memValue;

			if (this.num1) {
				this.num2 = this.memValue;
			}

			this.updateDisplay();
		}
	},

	memClear: function() {
		this.memValue = '0';
	},

	calculate: function(o1, o2, op) {
		var result;
		if (op == '=') {
			result = o1 = o2;
			o2 = '';
		}
		else {
			if (op == '%') {
				result = arguments[0] + '/' + arguments[1];
				result = eval(result);
				result = result * 100;
				return result;
			} else {
				result = arguments[0] + arguments[2] + arguments[1];
			}
			result = eval(result);
		}

		return result;
	},

	operation: function(op) {
		if (op == '%') {
			this.operator = '%';
		}
		if (this.num1 == '' && typeof (this.num1) == 'string') {
			this.num1 = parseFloat(this.number);
			this.operator = op;
			this.addToNum = 'no';
		}
		else {
			if (this.addToNum == 'yes') {
				this.num2 = parseFloat(this.number);
				this.num1 = this.calculate(this.num1, this.num2, this.operator);
				this.number = String(this.num1);
				this.updateDisplay();
				this.operator = op;
				this.addToNum = 'no';
			}
			else {
				this.operator = op;
				this.addToNum = 'no';
			}
		}
	},

	divisionToX: function() {
		if (this.number != '' && typeof (this.number) == 'string') {
			var xValue = parseFloat(this.number);
			this.number = 1 / xValue;
			this.updateDisplay();
			this.addToNum = 'reset';
		}
	},

	equals: function() {
		if (this.addToNum == 'yes') {
			if (this.num1 == '' && typeof (this.num1) == 'string') {
				this.operator = '=';
				this.num1 = parseFloat(this.number);
				this.addToNum = 'no';
			}
			else {
				this.num2 = parseFloat(this.number);
				this.num1 = this.calculate(this.num1, this.num2, this.operator);
				this.number = String(this.num1);
				this.updateDisplay();
				this.addToNum = 'reset';
			}
		}
		else {
			if (this.num1 == '' && typeof (this.num1) == 'string') {
				return;
			}
			else {
				if (this.num2 == '' && typeof (this.num2) == 'string') {
					this.num2 = this.num1;
				}
				this.num1 = this.calculate(this.num1, this.num2, this.operator);
				this.number = String(this.num1);
				this.updateDisplay();
				this.addToNum = 'reset';
			}
		}
	}
});

Ext.reg('calculator', Terrasoft.Calculator);
