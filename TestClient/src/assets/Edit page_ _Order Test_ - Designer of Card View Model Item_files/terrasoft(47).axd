Terrasoft.DatePicker = Ext.extend(Ext.LayoutControl, {
	format: "d.m.Y",
	constrainToViewport: true,
	startDay: 1,
	showToday: true,
	showYesterday: true,
	showTomorrow: true,
	isFormField: true,
	isMenu: false,
	mimicing: false,

	initComponent: function() {
		Terrasoft.DatePicker.superclass.initComponent.call(this);
		if (!this.isMenu) {
			this.addEvents(
			'focus',
			'blur',
			'change'
			);
		}
		var value = this.parseDate(this.value);
		this.value = Ext.isDate(value) ?
			value.clearTime() : new Date().clearTime();
		this.oldValue = this.value;
		this.addEvents('select');
		if (this.handler) {
			this.on("select", this.handler, this.scope || this);
		}
		this.initDisabledDays();
		this.startDay = parseInt(Terrasoft.CultureInfo.startDay);
	},

	initDisabledDays: function() {
		if (!this.disabledDatesRE && this.disabledDates) {
			var dd = this.disabledDates;
			var re = "(?:";
			for (var i = 0; i < dd.length; i++) {
				re += dd[i];
				if (i != dd.length - 1) re += "|";
			}
			this.disabledDatesRE = new RegExp(re + ")");
		}
	},

	onRender: function(container, position) {
		Terrasoft.DatePicker.superclass.onRender.call(this, container, position);
		var m = [];
		m.push('<table class="x-datetime" cellspacing="0" width = "310">',
				'<tbody><tr>',
				'<td colspan = "2" class = "x-dp-header">',
				'<div class="x-date-year-prev"><div class = "x-date-year-prev-arrow"><br></div></div>',
				'<div class="x-date-middle"></div>',
				'<div class="x-date-year-next"><div class = "x-date-year-next-arrow"><br></div></div>',
				'</td>',
				'<tr><td class="x-date-monthlist">',
				this.getMonthListHtml(),
				'</td>',
				'<td>');
		m.push('<table class="x-date-daylist" cellspacing="0"><thead><tr>');
		var dn = this.getDayNames();
		for (var i = 0; i < 7; i++) {
			var d = this.startDay + i;
			if (d > 6) {
				d = d - 7;
			}
			m.push("<th><span>", dn[d], "</span></th>");
		}
		m[m.length] = "</tr></thead><tbody><tr>";
		for (var i = 0; i < 42; i++) {
			if (i % 7 == 0 && i != 0) {
				m[m.length] = "</tr><tr>";
			}
			m[m.length] = '<td><a href="#" hidefocus="on" class="x-date-date"><em><span></span></em></a></td>';
		}
		m.push('</tr></tbody></table>');
		this.el = container.createChild({
			id: this.getId(),
			cls: "x-date-picker"
		});
		this.el.dom.innerHTML = m.join("");
		if (!this.isMenu) {
			var lastFocusEl = {
				tag: "a", cls: "x-menu-focus", href: "#", onclick: "return false;", tabIndex: "-1"
			}
			this.lastFocusEl = Ext.DomHelper.insertAfter(this.el, lastFocusEl, true);
		}
		this.eventEl = Ext.get(this.el.dom.firstChild);
		if (this.hiddenName) {
			this.hiddenField = this.el.createChild({ tag: 'input', type: 'hidden', name: this.hiddenName,
				id: this.hiddenName
			}, undefined, true);
			if (this.value) {
				this.hiddenField.value = this.value.dateFormat(this.format) || "";
			}
		}
		var xDateYearPrev = this.el.child(".x-date-year-prev");
		xDateYearPrev.addClassOnOver("x-date-year-prev-over");
		xDateYearPrev.addClassOnClick("x-date-year-click");
		new Ext.util.ClickRepeater(xDateYearPrev, {
			handler: this.showPrevYear,
			scope: this,
			preventDefault: true,
			stopDefault: true
		});

		var xDateYearNext = this.el.child(".x-date-year-next");
		xDateYearNext.addClassOnOver("x-date-year-next-over");
		xDateYearNext.addClassOnClick("x-date-year-click");
		new Ext.util.ClickRepeater(xDateYearNext, {
			handler: this.showNextYear,
			scope: this,
			preventDefault: true,
			stopDefault: true
		});

		this.eventEl.on("mousewheel", this.handleMouseWheel, this);
		this.monthList = this.el.select('td.x-date-monthlist table').first();
		this.monthList.on('click', this.onMonthClick, this);

		this.mlMonths = this.monthList.select('td.x-date-ml-month');
		this.mlMonths.each(function(m, a, i) {
			i += 1;
			if ((i % 2) == 0) {
				m.dom.xmonth = 5 + Math.round(i * .5);
			} else {
				m.dom.xmonth = Math.round((i - 1) * .5);
			}
			m.addClassOnOver('x-date-ml-month-over');
		});

		var kn = new Ext.KeyNav(this.eventEl, {
			"left": function(e) {
				if (e.ctrlKey) {
					this.showPrevMonth();
					return;
				}
				var activeDate = this.activeDate.add("d", -1);
				if (!this.isMenu && !this.isDisabledDate(activeDate)) {
					this.setValue(activeDate);
				}
				this.update(activeDate);
			},

			"right": function(e) {
				if (e.ctrlKey) {
					this.showNextMonth();
					return;
				}
				var activeDate = this.activeDate.add("d", 1);
				if (!this.isMenu && !this.isDisabledDate(activeDate)) {
					this.setValue(activeDate);
				}
				this.update(activeDate);
			},

			"up": function(e) {
				if (e.ctrlKey) {
					this.showNextYear();
					return;
				}
				var activeDate = this.activeDate.add("d", -7);
				if (!this.isMenu && !this.isDisabledDate(activeDate)) {
					this.setValue(activeDate);
				}
				this.update(activeDate);
			},

			"down": function(e) {
				if (e.ctrlKey) {
					this.showPrevYear();
					return;
				}
				var activeDate = this.activeDate.add("d", 7);
				if (!this.isMenu && !this.isDisabledDate(activeDate)) {
					this.setValue(activeDate);
				}
				this.update(activeDate);
			},

			"pageUp": function(e) {
				this.showNextMonth();
			},

			"pageDown": function(e) {
				this.showPrevMonth();
			},

			"enter": function(e) {
				e.stopPropagation();
				return true;
			},
			forceKeyDown: true,
			scope: this
		});
		this.eventEl.on("click", this.handleDateClick, this, { delegate: "a.x-date-date" });
		this.el.unselectable();
		this.daysListHeaderCells = this.el.select("table.x-date-daylist thead th");
		var startDay = this.startDay;
		var saturdayIndex = 6 - startDay;
		var sundayIndex = (7 - startDay) % 7;
		this.daysListHeaderCells.item(saturdayIndex).addClass("x-date-dl-day-weekend");
		this.daysListHeaderCells.item(sundayIndex).addClass("x-date-dl-day-weekend");
		this.cells = this.el.select("table.x-date-daylist tbody td");
		this.cells.each(function(el, thisObject, index) {
			if (!this.isMenu) {
				el.child('a').on('focus', this.onFocus, this);
				el.child('a').on('keydown', this.captureTabKeyDown, this);
			}
			el.addClassOnOver('x-date-dl-day-over');
		}, this);
		this.textNodes = this.el.query("table.x-date-daylist tbody span");

		this.yearEdit = new Ext.form.TextField({
			width: 35,
			renderTo: this.el.child(".x-date-middle", true)
		});
		this.focusEl = this.yearEdit.el;
		var buttonsContainer = this.el.child("td.x-dp-header", true);
		if (this.showYesterday) {
			this.yesterdayBtn = new Terrasoft.Button({
				renderTo: buttonsContainer,
				caption: this.getYesterdayText(),
				handler: this.selectYesterday,
				cls: "x-dp-btn",
				height: 19,
				width: 70,
				autoWidth: false,
				scope: this
			});
		}
		if (this.showToday) {
			this.todayKeyListener = this.eventEl.addKeyListener(Ext.EventObject.SPACE, this.selectToday, this);
			this.todayBtn = new Terrasoft.Button({
				renderTo: buttonsContainer,
				caption: this.getTodayText(),
				handler: this.selectToday,
				cls: "x-dp-btn x-dp-btn-today",
				height: 19,
				width: 75,
				autoWidth: false,
				scope: this
			});
		}
		if (this.showTomorrow) {
			this.tomorrowBtn = new Terrasoft.Button({
				renderTo: buttonsContainer,
				caption: this.getTomorrowText(),
				handler: this.selectTomorrow,
				cls: "x-dp-btn",
				height: 19,
				width: 70,
				autoWidth: false,
				scope: this
			});
		}
		if (Ext.isIE) {
			this.el.repaint();
		}
		if (!this.isMenu) {
			this.focusEl.on('focus', this.onFocus, this);
		}
		this.updateMonthList();
		this.update(this.value);
	},

	setSize: Ext.emptyFn,

	parseDate: function(value) {
		if (!value || Ext.isDate(value)) {
			return value;
		}
		var v = Date.parseDate(value, this.format);
		if (Ext.isDate(value)) {
			value.clearTime();
		}
		if (!v && this.altFormats) {
			if (!this.altFormatsArray) {
				this.altFormatsArray = this.altFormats.split("|");
			}
			for (var i = 0, len = this.altFormatsArray.length; i < len && !v; i++) {
				v = Date.parseDate(value, this.altFormatsArray[i]);
			}
		}
		return v;
	},

	setDisabledDates: function(dd) {
		if (Ext.isArray(dd)) {
			this.disabledDates = dd;
			this.disabledDatesRE = null;
		} else {
			this.disabledDatesRE = dd;
		}
		this.initDisabledDays();
		this.update(this.value, true);
	},

	setDisabledDays: function(dd) {
		this.disabledDays = dd;
		this.update(this.value, true);
	},

	setMinDate: function(dt) {
		this.minDate = dt;
		this.update(this.value, true);
	},

	setMaxDate: function(dt) {
		this.maxDate = dt;
		this.update(this.value, true);
	},

	setValue: function(value) {
		var value = this.parseDate(value);
		if (this.hiddenField) {
			var formattedDate = (value) ? value.dateFormat(this.format) : "";
			this.hiddenField.value = formattedDate;
		}
		this.value = value;
		if (this.el) {
			this.update(this.value);
		}
	},

	getValue: function() {
		return this.value;
	},

	focus: function() {
		if (!this.isMenu) {
			this.focusEl.focus();
		}
		if (this.el) {
			this.update(this.activeDate);
		}
	},

	onFocus: function() {
		if (!this.enabled) {
			return;
		}
		if (!this.mimicing) {
			this.mimicing = true;
			Ext.get(Ext.isIE ? document.body : document).on("mousedown", this.mimicBlur, this, { delay: 10 });
			this.focusEl.on('keydown', this.checkTab, this);
			this.fireEvent("focus", this);
		}
	},

	mimicBlur: function(e) {
		if (!this.el.contains(e.target)) {
			this.onBlur();
		}
	},

	onBlur: function() {
		Ext.get(Ext.isIE ? document.body : document).un("mousedown", this.mimicBlur, this);
		this.focusEl.un('keydown', this.checkTab, this);
		this.mimicing = false;
		var value = this.getValue();
		if (String(value) !== String(this.oldValue)) {
			this.fireEvent("change", this, Ext.isDate(value) ? Ext.util.JSON.encodeDate(value) : "",
				(this.oldValue) ? Ext.util.JSON.encodeDate(this.oldValue) : "");
			this.oldValue = value;
		}
		this.fireEvent("blur", this);
	},

	captureTabKeyDown: function(e) {
		if (e.getKey() == e.TAB) {
			if (e.shiftKey) {
				this.tomorrowBtn.el.button.focus();
			} else {
				this.lastFocusEl.focus();
				if (this.enabled) {
					this.onBlur();
				}
			}
		}
	},

	checkTab: function(e) {
		if (!this.enabled) {
			return;
		}
		if ((e.getKey() == e.TAB) && e.shiftKey) {
			this.onBlur();
		}
	},

	onEnable: function() {
		Terrasoft.DatePicker.superclass.onEnable.call(this);
		if (this.todayBtn) {
			this.todayBtn.enable();
		}
		if (this.yesterdayBtn) {
			this.yesterdayBtn.enable();
		}
		if (this.tomorrowBtn) {
			this.tomorrowBtn.enable();
		}
		this.yearEdit.enable();
		this.update(this.activeDate, true);
	},

	onDisable: function() {
		if (this.todayBtn) {
			this.todayBtn.disable();
		}
		if (this.yesterdayBtn) {
			this.yesterdayBtn.disable();
		}
		if (this.tomorrowBtn) {
			this.tomorrowBtn.disable();
		}
		this.yearEdit.disable();
		Terrasoft.DatePicker.superclass.onDisable.call(this);
	},

	getMonthListHtml: function() {
		var buf = ['<table border="0" cellspacing="0"'];
		for (var i = 0; i < 6; i++) {
			buf.push(
				'<tr><td class="x-date-ml-month">', this.getMonthNames()[i], '</td>',
				'<td class="x-date-ml-month leftborder">', this.getMonthNames()[i + 6], '</td>', '</tr>');
		};
		buf.push('</table>');
		return buf.join("");
	},

	updateMonthList: function() {
		this.mpSelMonth = (this.activeDate || this.value).getMonth();
		this.mlCurrentMonth = new Date().getMonth();
		this.updateMonth(this.mpSelMonth, this.mlCurrentMonth);
	},

	updateMonth: function(sm, cm) {
		this.mlMonths.each(function(m, a, i) {
			m[m.dom.xmonth == sm ? 'addClass' : 'removeClass']('x-date-ml-month-selected');
			m[m.dom.xmonth == cm ? 'addClass' : 'removeClass']('x-date-ml-month-current');
		});
	},

	clearDaysListHeader: function() {
		this.daysListHeaderCells.each(function(el, thisObject, index) {
			el.removeClass("x-date-dl-day-current");
		});
	},

	onMonthClick: function(e, t) {
		if (!this.enabled) {
			return;
		}
		var el = new Ext.Element(t);
		if (el.hasClass('x-date-ml-month')) {
			e.stopEvent()
		} else {
			return;
		}
		var pn = el;
		if (pn) {
			this.mlMonths.removeClass('x-date-ml-month-selected');
			pn.addClass('x-date-ml-month-selected');
			this.mpSelMonth = pn.dom.xmonth;
		}
		var currentDay = (this.activeDate || this.value).getDate();
		var currentYear = (this.activeDate || this.value).getFullYear();
		var daysInSelectedMonth = new Date(currentYear, this.mpSelMonth).getDaysInMonth();
		if (currentDay > daysInSelectedMonth) {
			currentDay = daysInSelectedMonth;
		}
		var d = new Date(currentYear, this.mpSelMonth, currentDay);
		if (!this.isMenu && !this.isDisabledDate(d)) {
			this.setValue(d);
		}
		this.update(d, false, isMonthListClick = true);
	},

	showPrevMonth: function(e) {
		if (!this.enabled) {
			return;
		}
		var activeDate = this.activeDate.add("mo", -1);
		if (!this.isMenu && !this.isDisabledDate(activeDate)) {
			this.setValue(activeDate);
		}
		this.update(activeDate);
	},

	showNextMonth: function(e) {
		var activeDate = this.activeDate.add("mo", 1);
		if (!this.isMenu && !this.isDisabledDate(activeDate)) {
			this.setValue(activeDate);
		}
		this.update(activeDate);
	},

	showPrevYear: function() {
		if (!this.enabled) {
			return;
		}
		var activeDate = this.activeDate.add("y", -1);
		if (!this.isMenu && !this.isDisabledDate(activeDate)) {
			this.setValue(activeDate);
		}
		this.update(activeDate);
	},

	showNextYear: function() {
		if (!this.enabled) {
			return;
		}
		var activeDate = this.activeDate.add("y", 1);
		if (!this.isMenu && !this.isDisabledDate(activeDate)) {
			this.setValue(activeDate);
		}
		this.update(activeDate);
	},

	handleMouseWheel: function(e) {
		if (!this.enabled) {
			return;
		}
		var delta = e.getWheelDelta();
		if (delta > 0) {
			this.showPrevMonth();
			e.stopEvent();
		} else if (delta < 0) {
			this.showNextMonth();
			e.stopEvent();
		}
	},

	handleDateClick: function(e, t) {
		if (!this.enabled) {
			return;
		}
		e.stopEvent();
		if (t.dateValue && !Ext.fly(t.parentNode).hasClass("x-date-disabled")) {
			this.setValue(new Date(t.dateValue));
			this.fireEvent("select", this, this.value);
		}
	},

	selectToday: function() {
		if (this.todayBtn && !this.todayBtn.disabled) {
			this.setValue(new Date().clearTime());
			this.fireEvent("select", this, this.value);
		}
	},

	selectTomorrow: function() {
		if (this.tomorrowBtn && !this.tomorrowBtn.disabled) {
			this.setValue((new Date().clearTime()).add("d", 1));
			this.fireEvent("select", this, this.value);
		}
	},

	selectYesterday: function() {
		if (this.yesterdayBtn && !this.yesterdayBtn.disabled) {
			this.setValue((new Date().clearTime()).add("d", -1));
			this.fireEvent("select", this, this.value);
		}
	},

	isDisabledDate: function(date) {
		var min = this.minDate ? this.minDate.clearTime() : Number.NEGATIVE_INFINITY;
		var max = this.maxDate ? this.maxDate.clearTime() : Number.POSITIVE_INFINITY;
		var ddMatch = this.disabledDatesRE;
		var ddays = this.disabledDays ? this.disabledDays.join("") : false;
		var format = this.format;
		var result = (date < min || date > max ||
			(ddMatch && format && ddMatch.test(date.dateFormat(format))) ||
			(ddays && ddays.indexOf(date.getDay()) != -1));
		return result;
	},

	update: function(date, forceRefresh, isMonthListClick) {
		var vd = this.activeDate;
		this.activeDate = date;
		if (!forceRefresh && vd && this.el) {
			var t = date.getTime();
			if (vd.getMonth() == date.getMonth() && vd.getFullYear() == date.getFullYear()) {
				this.cells.removeClass("x-date-selected");
				this.cells.each(function(c) {
					if (c.dom.firstChild.dateValue == t) {
						c.addClass("x-date-selected");
						setTimeout(function() {
							try { c.dom.firstChild.focus(); } catch (e) { }
						}, 50);
						return false;
					}
				});
				return;
			}
		}
		var days = date.getDaysInMonth();
		var firstOfMonth = date.getFirstDateOfMonth();
		var startingPos = firstOfMonth.getDay() - this.startDay;

		if (startingPos <= this.startDay) {
			startingPos += 7;
		}

		var pm = date.add("mo", -1);
		var prevStart = pm.getDaysInMonth() - startingPos;

		var cells = this.cells.elements;
		var textEls = this.textNodes;
		days += startingPos;

		var day = 86400000;
		var d = (new Date(pm.getFullYear(), pm.getMonth(), prevStart)).clearTime();
		var today = new Date().clearTime().getTime();
		var sel = date.clearTime().getTime();
		var min = this.minDate ? this.minDate.clearTime() : Number.NEGATIVE_INFINITY;
		var max = this.maxDate ? this.maxDate.clearTime() : Number.POSITIVE_INFINITY;
		var ddMatch = this.disabledDatesRE;
		var ddays = this.disabledDays ? this.disabledDays.join("") : false;
		var format = this.format;

		if (this.showToday) {
			var td = new Date().clearTime();
			var disable = this.isDisabledDate(td);
			this.todayBtn.setDisabled(disable);
			this.todayKeyListener[disable ? 'disable' : 'enable']();
		}
		if (this.showYesterday) {
			var yd = ((new Date()).add("d", -1)).clearTime();
			var disable = this.isDisabledDate(yd);
			this.yesterdayBtn.setDisabled(disable);
		}
		if (this.showTomorrow) {
			var tm = ((new Date()).add("d", 1)).clearTime();
			var disable = this.isDisabledDate(tm);
			this.tomorrowBtn.setDisabled(disable);
		}
		var setCellClass = function(cal, cell) {
			cell.title = "";
			var t = d.getTime();
			cell.firstChild.dateValue = t;
			if (t == today) {
				cell.className += " x-date-dl-day-current";
				cal.daysListHeaderCells.item(cell.cellIndex).addClass("x-date-dl-day-current");
			}
			if (t == sel) {
				cell.className += " x-date-selected";
				setTimeout(function() {
					try { cell.firstChild.focus(); } catch (e) { }
				}, 50);
			}

			if (t < min) {
				cell.className = " x-date-disabled";
				return;
			}
			if (t > max) {
				cell.className = " x-date-disabled";
				return;
			}
			if (ddays) {
				if (ddays.indexOf(d.getDay()) != -1) {
					cell.className = " x-date-disabled";
				}
			}
			if (ddMatch && format) {
				var fvalue = d.dateFormat(format);
				if (ddMatch.test(fvalue)) {
					cell.className = " x-date-disabled";
				}
			}
		};
		this.clearDaysListHeader();
		var i = 0;
		for (; i < startingPos; i++) {
			textEls[i].innerHTML = (++prevStart);
			d.setDate(d.getDate() + 1);
			cells[i].className = "x-date-prevday";
			setCellClass(this, cells[i]);
		}
		for (; i < days; i++) {
			intDay = i - startingPos + 1;
			textEls[i].innerHTML = (intDay);
			d.setDate(d.getDate() + 1);
			cells[i].className = "x-date-active";
			setCellClass(this, cells[i]);
		}
		var extraDays = 0;
		for (; i < 42; i++) {
			textEls[i].innerHTML = (++extraDays);
			d.setDate(d.getDate() + 1);
			cells[i].className = "x-date-nextday";
			setCellClass(this, cells[i]);
		}
		var startDay = this.startDay;
		var saturdayIndex = 6 - startDay;
		var sundayIndex = (7 - startDay) % 7;
		for (var i = 0; i < 43; i += 7) {
			if (i + sundayIndex >= 43 || i + saturdayIndex >= 43) {
				break;
			}
			cells[i + saturdayIndex].className += " x-date-dl-day-weekend";
			cells[i + sundayIndex].className += " x-date-dl-day-weekend";
		}

		this.yearEdit.setValue(date.getFullYear());
		if (vd && (vd.getMonth() != date.getMonth()) && !isMonthListClick) {
			this.updateMonthList();
		}

		if (!this.internalRender) {
			var main = this.el.dom.firstChild;
			var w = main.offsetWidth;
			this.el.setWidth(w + this.el.getBorderWidth("lr"));
			Ext.fly(main).setWidth(w);
			this.internalRender = true;

			if (Ext.isOpera && !this.secondPass) {
				main.rows[0].cells[1].style.width = (w - (main.rows[0].cells[0].offsetWidth + main.rows[0].cells[2].offsetWidth)) + "px";
				this.secondPass = true;
				this.update.defer(10, this, [date]);
			}
		}
	},

	beforeDestroy: function() {
		if (this.rendered) {
			Ext.destroy(this.yearEdit, this.yesterdayBtn, this.todayBtn, this.tomorrowBtn);
		}
	},

	getTodayText: function() {
		if (this.todayText != undefined) {
			return this.todayText;
		}
		this.todayText = Ext.StringList('WC.DateTime').getValue('QuickDay.Today');
		return this.todayText;
	},

	getTomorrowText: function() {
		if (this.tomorrowText != undefined) {
			return this.tomorrowText;
		}
		this.tomorrowText = Ext.StringList('WC.DateTime').getValue('QuickDay.Tomorrow');
		return this.tomorrowText;
	},

	getYesterdayText: function() {
		if (this.yesterdayText != undefined) {
			return this.yesterdayText;
		}
		this.yesterdayText = Ext.StringList('WC.DateTime').getValue('QuickDay.Yesterday');
		return this.yesterdayText;
	},

	getMonthNames: function() {
		if (!this.monthNames) {
			this.monthNames = Terrasoft.CultureInfo.monthNames;
		}
		return this.monthNames;
	},

	getDayNames: function() {
		if (!this.dayNames) {
			this.dayNames = Terrasoft.CultureInfo.shortDayNames;
		}
		return this.dayNames;
	}

});

Ext.reg('datepicker', Terrasoft.DatePicker);
