Ext.DomHelper = function () {
	var tempTableEl = null;
	var emptyTags = /^(?:br|frame|hr|img|input|link|meta|range|spacer|wbr|area|param|col)$/i;
	var tableRe = /^table|tbody|tr|td$/i;

	var createHtml = function (o) {
		if (typeof o == 'string') {
			return o;
		}
		var b = "";
		if (Ext.isArray(o)) {
			for (var i = 0, l = o.length; i < l; i++) {
				b += createHtml(o[i]);
			}
			return b;
		}
		if (!o.tag) {
			o.tag = "div";
		}
		b += "<" + o.tag;
		for (var attr in o) {
			if (attr == "tag" || attr == "children" || attr == "cn" || attr == "html" || typeof o[attr] == "function") continue;
			if (attr == "style") {
				var s = o["style"];
				if (typeof s == "function") {
					s = s.call();
				}
				if (typeof s == "string") {
					b += ' style="' + s + '"';
				} else if (typeof s == "object") {
					b += ' style="';
					for (var key in s) {
						if (typeof s[key] != "function") {
							b += key + ":" + s[key] + ";";
						}
					}
					b += '"';
				}
			} else {
				if (attr == "cls") {
					b += ' class="' + o["cls"] + '"';
				} else if (attr == "htmlFor") {
					b += ' for="' + o["htmlFor"] + '"';
				} else {
					b += " " + attr + '="' + o[attr] + '"';
				}
			}
		}
		if (emptyTags.test(o.tag)) {
			b += "/>";
		} else {
			b += ">";
			var cn = o.children || o.cn;
			if (cn) {
				b += createHtml(cn);
			} else if (o.html) {
				b += o.html;
			}
			b += "</" + o.tag + ">";
		}
		return b;
	};

	var createDom = function (o, parentNode) {
		var el;
		if (Ext.isArray(o)) {
			el = document.createDocumentFragment(); for (var i = 0, l = o.length; i < l; i++) {
				createDom(o[i], el);
			}
		} else if (typeof o == "string") {
			el = document.createTextNode(o);
		} else {
			el = document.createElement(o.tag || 'div');
			var useSet = !!el.setAttribute; for (var attr in o) {
				if (attr == "tag" || attr == "children" || attr == "cn" || attr == "html" || attr == "style" || typeof o[attr] == "function") continue;
				if (attr == "cls") {
					el.className = o["cls"];
				} else {
					if (useSet) el.setAttribute(attr, o[attr]);
					else el[attr] = o[attr];
				}
			}
			Ext.DomHelper.applyStyles(el, o.style);
			var cn = o.children || o.cn;
			if (cn) {
				createDom(cn, el);
			} else if (o.html) {
				el.innerHTML = o.html;
			}
		}
		if (parentNode) {
			parentNode.appendChild(el);
		}
		return el;
	};

	var ieTable = function (depth, s, h, e) {
		tempTableEl.innerHTML = [s, h, e].join('');
		var i = -1, el = tempTableEl;
		while (++i < depth) {
			el = el.firstChild;
		}
		return el;
	};

	var ts = '<table>',
        te = '</table>',
        tbs = ts + '<tbody>',
        tbe = '</tbody>' + te,
        trs = tbs + '<tr>',
        tre = '</tr>' + tbe;

	var insertIntoTable = function (tag, where, el, html) {
		if (!tempTableEl) {
			tempTableEl = document.createElement('div');
		}
		var node;
		var before = null;
		if (tag == 'td') {
			if (where == 'afterbegin' || where == 'beforeend') {
				return;
			}
			if (where == 'beforebegin') {
				before = el;
				el = el.parentNode;
			} else {
				before = el.nextSibling;
				el = el.parentNode;
			}
			node = ieTable(4, trs, html, tre);
		}
		else if (tag == 'tr') {
			if (where == 'beforebegin') {
				before = el;
				el = el.parentNode;
				node = ieTable(3, tbs, html, tbe);
			} else if (where == 'afterend') {
				before = el.nextSibling;
				el = el.parentNode;
				node = ieTable(3, tbs, html, tbe);
			} else {
				if (where == 'afterbegin') {
					before = el.firstChild;
				}
				node = ieTable(4, trs, html, tre);
			}
		} else if (tag == 'tbody') {
			if (where == 'beforebegin') {
				before = el;
				el = el.parentNode;
				node = ieTable(2, ts, html, te);
			} else if (where == 'afterend') {
				before = el.nextSibling;
				el = el.parentNode;
				node = ieTable(2, ts, html, te);
			} else {
				if (where == 'afterbegin') {
					before = el.firstChild;
				}
				node = ieTable(3, tbs, html, tbe);
			}
		} else {
			if (where == 'beforebegin' || where == 'afterend') {
				return;
			}
			if (where == 'afterbegin') {
				before = el.firstChild;
			}
			node = ieTable(2, ts, html, te);
		}
		el.insertBefore(node, before);
		return node;
	};

	return {
		useDom: false,

		markup: function (o) {
			return createHtml(o);
		},

		applyStyles: function (el, styles) {
			if (styles) {
				el = Ext.fly(el);
				if (typeof styles == "string") {
					var re = /\s?([a-z\-]*)\:\s?([^;]*);?/gi;
					var matches;
					while ((matches = re.exec(styles)) != null) {
						el.setStyle(matches[1], matches[2]);
					}
				} else if (typeof styles == "object") {
					for (var style in styles) {
						el.setStyle(style, styles[style]);
					}
				} else if (typeof styles == "function") {
					Ext.DomHelper.applyStyles(el, styles.call());
				}
			}
		},

		insertHtml: function (where, el, html) {
			where = where.toLowerCase();
			if (el.insertAdjacentHTML) {
				if (tableRe.test(el.tagName)) {
					var rs;
					if (rs = insertIntoTable(el.tagName.toLowerCase(), where, el, html)) {
						return rs;
					}
				}
				switch (where) {
					case "beforebegin":
						el.insertAdjacentHTML('BeforeBegin', html);
						return el.previousSibling;
					case "afterbegin":
						el.insertAdjacentHTML('AfterBegin', html);
						return el.firstChild;
					case "beforeend":
						el.insertAdjacentHTML('BeforeEnd', html);
						return el.lastChild;
					case "afterend":
						el.insertAdjacentHTML('AfterEnd', html);
						return el.nextSibling;
				}
				throw 'Недопустимая точка вставки -> "' + where + '"';
			}
			var range = el.ownerDocument.createRange();
			if (typeof Range.prototype.createContextualFragment == "undefined") {
				Range.prototype.createContextualFragment = function (html) {
					var doc = window.document;
					var container = doc.createElement("div");
					container.innerHTML = html;
					var frag = doc.createDocumentFragment(), n;
					while ((n = container.firstChild)) {
						frag.appendChild(n);
					}
					return frag;
				};
			}
			var frag;
			switch (where) {
				case "beforebegin":
					range.setStartBefore(el);
					frag = range.createContextualFragment(html);
					el.parentNode.insertBefore(frag, el);
					return el.previousSibling;
				case "afterbegin":
					if (el.firstChild) {
						range.setStartBefore(el.firstChild);
						frag = range.createContextualFragment(html);
						el.insertBefore(frag, el.firstChild);
						return el.firstChild;
					} else {
						el.innerHTML = html;
						return el.firstChild;
					}
				case "beforeend":
					if (el.lastChild) {
						range.setStartAfter(el.lastChild);
						frag = range.createContextualFragment(html);
						el.appendChild(frag);
						return el.lastChild;
					} else {
						el.innerHTML = html;
						return el.lastChild;
					}
				case "afterend":
					range.setStartAfter(el);
					frag = range.createContextualFragment(html);
					el.parentNode.insertBefore(frag, el.nextSibling);
					return el.nextSibling;
			}
			throw 'Недопустимая точка вставки -> "' + where + '"';
		},

		insertBefore: function (el, o, returnElement) {
			return this.doInsert(el, o, returnElement, "beforeBegin");
		},

		insertAfter: function (el, o, returnElement) {
			return this.doInsert(el, o, returnElement, "afterEnd", "nextSibling");
		},

		insertFirst: function (el, o, returnElement) {
			return this.doInsert(el, o, returnElement, "afterBegin", "firstChild");
		},

		doInsert: function (el, o, returnElement, pos, sibling) {
			el = Ext.getDom(el);
			var newNode;
			if (this.useDom) {
				newNode = createDom(o, null);
				(sibling === "firstChild" ? el : el.parentNode).insertBefore(newNode, sibling ? el[sibling] : el);
			} else {
				var html = createHtml(o);
				newNode = this.insertHtml(pos, el, html);
			}
			return returnElement ? Ext.get(newNode, true) : newNode;
		},

		append: function (el, o, returnElement) {
			el = Ext.getDom(el);
			var newNode;
			if (this.useDom) {
				newNode = createDom(o, null);
				el.appendChild(newNode);
			} else {
				var html = createHtml(o);
				newNode = this.insertHtml("beforeEnd", el, html);
			}
			return returnElement ? Ext.get(newNode, true) : newNode;
		},

		overwrite: function (el, o, returnElement) {
			el = Ext.getDom(el);
			if (o.tag == 'tr') {
				el.insertRow(0);
			} else {
				el.innerHTML = createHtml(o);
			}
			return returnElement ? Ext.get(el.firstChild, true) : el.firstChild;
		},

		createTemplate: function (o) {
			var html = createHtml(o);
			return new Ext.Template(html);
		}
	};
} ();

Ext.Template = function (html) {
	var a = arguments;
	if (Ext.isArray(html)) {
		html = html.join("");
	} else if (a.length > 1) {
		var buf = [];
		for (var i = 0, len = a.length; i < len; i++) {
			if (typeof a[i] == 'object') {
				Ext.apply(this, a[i]);
			} else {
				buf[buf.length] = a[i];
			}
		}
		html = buf.join('');
	}
	this.html = html;
	if (this.compiled) {
		this.compile();
	}
};

Ext.Template.prototype = {
	applyTemplate: function (values) {
		if (this.compiled) {
			return this.compiled(values);
		}
		var useF = this.disableFormats !== true;
		var fm = Ext.util.Format, tpl = this;
		var fn = function (m, name, format, args) {
			if (format && useF) {
				if (format.substr(0, 5) == "this.") {
					return tpl.call(format.substr(5), values[name], values);
				} else {
					if (args) {
						var re = /^\s*['"](.*)["']\s*$/;
						args = args.split(',');
						for (var i = 0, len = args.length; i < len; i++) {
							args[i] = args[i].replace(re, "$1");
						}
						args = [values[name]].concat(args);
					} else {
						args = [values[name]];
					}
					return fm[format].apply(fm, args);
				}
			} else {
				return values[name] !== undefined ? values[name] : "";
			}
		};
		return this.html.replace(this.re, fn);
	},

	set: function (html, compile) {
		this.html = html;
		this.compiled = null;
		if (compile) {
			this.compile();
		}
		return this;
	},

	disableFormats: false,

	re: /\{([\w-]+)(?:\:([\w\.]*)(?:\((.*?)?\))?)?\}/g,

	compile: function () {
		var fm = Ext.util.Format;
		var useF = this.disableFormats !== true;
		var sep = Ext.isGecko ? "+" : ",";
		var fn = function (m, name, format, args) {
			if (format && useF) {
				args = args ? ',' + args : "";
				if (format.substr(0, 5) != "this.") {
					format = "fm." + format + '(';
				} else {
					format = 'this.call("' + format.substr(5) + '", ';
					args = ", values";
				}
			} else {
				args = ''; format = "(values['" + name + "'] == undefined ? '' : ";
			}
			return "'" + sep + format + "values['" + name + "']" + args + ")" + sep + "'";
		};
		var body;
		if (Ext.isGecko) {
			body = "this.compiled = function(values){ return '" +
                   this.html.replace(/\\/g, '\\\\').replace(/(\r\n|\n)/g, '\\n').replace(/'/g, "\\'").replace(this.re, fn) +
                    "';};";
		} else {
			body = ["this.compiled = function(values){ return ['"];
			body.push(this.html.replace(/\\/g, '\\\\').replace(/(\r\n|\n)/g, '\\n').replace(/'/g, "\\'").replace(this.re, fn));
			body.push("'].join('');};");
			body = body.join('');
		}
		eval(body);
		return this;
	},

	call: function (fnName, value, allValues) {
		return this[fnName](value, allValues);
	},

	insertFirst: function (el, values, returnElement) {
		return this.doInsert('afterBegin', el, values, returnElement);
	},

	insertBefore: function (el, values, returnElement) {
		return this.doInsert('beforeBegin', el, values, returnElement);
	},

	insertAfter: function (el, values, returnElement) {
		return this.doInsert('afterEnd', el, values, returnElement);
	},

	append: function (el, values, returnElement) {
		return this.doInsert('beforeEnd', el, values, returnElement);
	},

	doInsert: function (where, el, values, returnEl) {
		el = Ext.getDom(el);
		var newNode = Ext.DomHelper.insertHtml(where, el, this.applyTemplate(values));
		return returnEl ? Ext.get(newNode, true) : newNode;
	},

	overwrite: function (el, values, returnElement) {
		el = Ext.getDom(el);
		el.innerHTML = this.applyTemplate(values);
		return returnElement ? Ext.get(el.firstChild, true) : el.firstChild;
	}
};

Ext.Template.prototype.apply = Ext.Template.prototype.applyTemplate;

Ext.DomHelper.Template = Ext.Template;

Ext.Template.from = function (el, config) {
	el = Ext.getDom(el);
	return new Ext.Template(el.value || el.innerHTML, config || '');
};

Ext.DomQuery = function () {
	var cache = {}, simpleCache = {}, valueCache = {};
	var nonSpace = /\S/;
	var trimRe = /^\s+|\s+$/g;
	var tplRe = /\{(\d+)\}/g;
	var modeRe = /^(\s?[\/>+~]\s?|\s|$)/;
	var tagTokenRe = /^(#)?([\w-\*]+)/;
	var nthRe = /(\d*)n\+?(\d*)/, nthRe2 = /\D/;

	function child(p, index) {
		var i = 0;
		var n = p.firstChild;
		while (n) {
			if (n.nodeType == 1) {
				if (++i == index) {
					return n;
				}
			}
			n = n.nextSibling;
		}
		return null;
	};

	function next(n) {
		while ((n = n.nextSibling) && n.nodeType != 1) {
		}
		return n;
	};

	function prev(n) {
		while ((n = n.previousSibling) && n.nodeType != 1) {
		}
		return n;
	};

	function children(d) {
		var n = d.firstChild, ni = -1;
		while (n) {
			var nx = n.nextSibling;
			if (n.nodeType == 3 && !nonSpace.test(n.nodeValue)) {
				d.removeChild(n);
			} else {
				n.nodeIndex = ++ni;
			}
			n = nx;
		}
		return this;
	};

	function byClassName(c, a, v) {
		if (!v) {
			return c;
		}
		var r = [], ri = -1, cn;
		for (var i = 0, ci; ci = c[i]; i++) {
			if ((' ' + ci.className + ' ').indexOf(v) != -1) {
				r[++ri] = ci;
			}
		}
		return r;
	};
	this["byClassName"] = byClassName;

	function attrValue(n, attr) {
		if (!n.tagName && typeof n.length != "undefined") {
			n = n[0];
		}
		if (!n) {
			return null;
		}
		if (attr == "for") {
			return n.htmlFor;
		}
		if (attr == "class" || attr == "className") {
			return n.className;
		}
		return n.getAttribute(attr) || n[attr];

	};

	function getNodes(ns, mode, tagName) {
		var result = [], ri = -1, cs;
		if (!ns) {
			return result;
		}
		tagName = tagName || "*";
		if (typeof ns.getElementsByTagName != "undefined") {
			ns = [ns];
		}
		if (!mode) {
			for (var i = 0, ni; ni = ns[i]; i++) {
				cs = ni.getElementsByTagName(tagName);
				for (var j = 0, ci; ci = cs[j]; j++) {
					result[++ri] = ci;
				}
			}
		} else if (mode == "/" || mode == ">") {
			var utag = tagName.toUpperCase();
			for (var i = 0, ni, cn; ni = ns[i]; i++) {
				cn = ni.children || ni.childNodes;
				for (var j = 0, cj; cj = cn[j]; j++) {
					if (cj.nodeName == utag || cj.nodeName == tagName || tagName == '*') {
						result[++ri] = cj;
					}
				}
			}
		} else if (mode == "+") {
			var utag = tagName.toUpperCase();
			for (var i = 0, n; n = ns[i]; i++) {
				while ((n = n.nextSibling) && n.nodeType != 1) {
				}
				if (n && (n.nodeName == utag || n.nodeName == tagName || tagName == '*')) {
					result[++ri] = n;
				}
			}
		} else if (mode == "~") {
			for (var i = 0, n; n = ns[i]; i++) {
				while ((n = n.nextSibling) && (n.nodeType != 1 || (tagName == '*' || n.tagName.toLowerCase() != tagName))) {
				}
				if (n) {
					result[++ri] = n;
				}
			}
		}
		return result;
	};
	this["getNodes"] = getNodes;

	function concat(a, b) {
		if (b.slice) {
			return a.concat(b);
		}
		for (var i = 0, l = b.length; i < l; i++) {
			a[a.length] = b[i];
		}
		return a;
	}

	function byTag(cs, tagName) {
		if (cs.tagName || cs == document) {
			cs = [cs];
		}
		if (!tagName) {
			return cs;
		}
		var r = [], ri = -1;
		tagName = tagName.toLowerCase();
		for (var i = 0, ci; ci = cs[i]; i++) {
			if (ci.nodeType == 1 && ci.tagName.toLowerCase() == tagName) {
				r[++ri] = ci;
			}
		}
		return r;
	};
	this["byTag"] = byTag;

	function byId(cs, attr, id) {
		if (cs.tagName || cs == document) {
			cs = [cs];
		}
		if (!id) {
			return cs;
		}
		var r = [], ri = -1;
		for (var i = 0, ci; ci = cs[i]; i++) {
			if (ci && ci.id == id) {
				r[++ri] = ci;
				return r;
			}
		}
		return r;
	};
	this["byId"] = byId;

	function byAttribute(cs, attr, value, op, custom) {
		var r = [], ri = -1, st = custom == "{";
		var f = Ext.DomQuery.operators[op];
		for (var i = 0, ci; ci = cs[i]; i++) {
			var a;
			if (st) {
				a = Ext.DomQuery.getStyle(ci, attr);
			}
			else if (attr == "class" || attr == "className") {
				a = ci.className;
			} else if (attr == "for") {
				a = ci.htmlFor;
			} else if (attr == "href") {
				a = ci.getAttribute("href", 2);
			} else {
				a = ci.getAttribute(attr);
			}
			if ((f && f(a, value)) || (!f && a)) {
				r[++ri] = ci;
			}
		}
		return r;
	};
	this["byAttribute"] = byAttribute;

	function byPseudo(cs, name, value) {
		return Ext.DomQuery.pseudos[name](cs, value);
	};
	this["byPseudo"] = byPseudo;

	var isIE = window.ActiveXObject ? true : false;

	eval("var batch = 30803;");

	var key = 30803;

	function nodupIEXml(cs) {
		var d = ++key;
		cs[0].setAttribute("_nodup", d);
		var r = [cs[0]];
		for (var i = 1, len = cs.length; i < len; i++) {
			var c = cs[i];
			if (!c.getAttribute("_nodup") != d) {
				c.setAttribute("_nodup", d);
				r[r.length] = c;
			}
		}
		for (var i = 0, len = cs.length; i < len; i++) {
			cs[i].removeAttribute("_nodup");
		}
		return r;
	}

	function nodup(cs) {
		if (!cs) {
			return [];
		}
		var len = cs.length, c, i, r = cs, cj, ri = -1;
		if (!len || typeof cs.nodeType != "undefined" || len == 1) {
			return cs;
		}
		if (isIE && typeof cs[0].selectSingleNode != "undefined") {
			return nodupIEXml(cs);
		}
		var d = ++key;
		cs[0]._nodup = d;
		for (i = 1; c = cs[i]; i++) {
			if (c._nodup != d) {
				c._nodup = d;
			} else {
				r = [];
				for (var j = 0; j < i; j++) {
					r[++ri] = cs[j];
				}
				for (j = i + 1; cj = cs[j]; j++) {
					if (cj._nodup != d) {
						cj._nodup = d;
						r[++ri] = cj;
					}
				}
				return r;
			}
		}
		return r;
	}
	this["nodup"] = nodup;

	function quickDiffIEXml(c1, c2) {
		var d = ++key;
		for (var i = 0, len = c1.length; i < len; i++) {
			c1[i].setAttribute("_qdiff", d);
		}
		var r = [];
		for (var i = 0, len = c2.length; i < len; i++) {
			if (c2[i].getAttribute("_qdiff") != d) {
				r[r.length] = c2[i];
			}
		}
		for (var i = 0, len = c1.length; i < len; i++) {
			c1[i].removeAttribute("_qdiff");
		}
		return r;
	}

	function quickDiff(c1, c2) {
		var len1 = c1.length;
		if (!len1) {
			return c2;
		}
		if (isIE && c1[0].selectSingleNode) {
			return quickDiffIEXml(c1, c2);
		}
		var d = ++key;
		for (var i = 0; i < len1; i++) {
			c1[i]._qdiff = d;
		}
		var r = [];
		for (var i = 0, len = c2.length; i < len; i++) {
			if (c2[i]._qdiff != d) {
				r[r.length] = c2[i];
			}
		}
		return r;
	}

	function quickId(ns, mode, root, id) {
		if (ns == root) {
			var d = root.ownerDocument || root;
			return d.getElementById(id);
		}
		ns = getNodes(ns, mode, "*");
		return byId(ns, null, id);
	}

	return {
		getStyle: function (el, name) {
			return Ext.fly(el).getStyle(name);
		},

		compile: function (path, type) {
			type = type || "select";

			var fn = ["var f = function(root){\n var mode; ++batch; var n = root || document;\n"];
			var q = path, mode, lq;
			var tk = Ext.DomQuery.matchers;
			var tklen = tk.length;
			var mm;

			var lmode = q.match(modeRe);
			if (lmode && lmode[1]) {
				fn[fn.length] = 'mode="' + lmode[1].replace(trimRe, "") + '";';
				q = q.replace(lmode[1], "");
			}

			while (path.substr(0, 1) == "/") {
				path = path.substr(1);
			}

			while (q && lq != q) {
				lq = q;
				var tm = q.match(tagTokenRe);
				if (type == "select") {
					if (tm) {
						if (tm[1] == "#") {
							fn[fn.length] = 'n = quickId(n, mode, root, "' + tm[2] + '");';
						} else {
							fn[fn.length] = 'n = getNodes(n, mode, "' + tm[2] + '");';
						}
						q = q.replace(tm[0], "");
					} else if (q.substr(0, 1) != '@') {
						fn[fn.length] = 'n = getNodes(n, mode, "*");';
					}
				} else {
					if (tm) {
						if (tm[1] == "#") {
							fn[fn.length] = 'n = byId(n, null, "' + tm[2] + '");';
						} else {
							fn[fn.length] = 'n = byTag(n, "' + tm[2] + '");';
						}
						q = q.replace(tm[0], "");
					}
				}
				while (!(mm = q.match(modeRe))) {
					var matched = false;
					for (var j = 0; j < tklen; j++) {
						var t = tk[j];
						var m = q.match(t.re);
						if (m) {
							fn[fn.length] = t.select.replace(tplRe, function (x, i) {
								return m[i];
							});
							q = q.replace(m[0], "");
							matched = true;
							break;
						}
					}

					if (!matched) {
						throw 'Ошибка парсинга селектора, парсинг завершился неудачей на  "' + q + '"';
					}
				}
				if (mm[1]) {
					fn[fn.length] = 'mode="' + mm[1].replace(trimRe, "") + '";';
					q = q.replace(mm[1], "");
				}
			}
			fn[fn.length] = "return nodup(n);\n}";
			eval(fn.join(""));
			return f;
		},

		select: function (path, root, type) {
			if (!root || root == document) {
				root = document;
			}
			if (typeof root == "string") {
				root = document.getElementById(root);
			}
			var paths = path.split(",");
			var results = [];
			for (var i = 0, len = paths.length; i < len; i++) {
				var p = paths[i].replace(trimRe, "");
				if (!cache[p]) {
					cache[p] = Ext.DomQuery.compile(p);
					if (!cache[p]) {
						throw p + " - недопустимый селектор ";
					}
				}
				var result = cache[p](root);
				if (result && result != document) {
					results = results.concat(result);
				}
			}
			if (paths.length > 1) {
				return nodup(results);
			}
			return results;
		},

		selectNode: function (path, root) {
			return Ext.DomQuery.select(path, root)[0];
		},

		selectValue: function (path, root, defaultValue) {
			path = path.replace(trimRe, "");
			if (!valueCache[path]) {
				valueCache[path] = Ext.DomQuery.compile(path, "select");
			}
			var n = valueCache[path](root);
			n = n[0] ? n[0] : n;
			if (Ext.isGecko) { // Fix Firefox Error
				n.normalize();
			}
			var v = (n && n.firstChild ? n.firstChild.nodeValue : null);
			return ((v === null || v === undefined || v === '') ? defaultValue : v);
		},

		selectNumber: function (path, root, defaultValue) {
			var v = Ext.DomQuery.selectValue(path, root, defaultValue || 0);
			return parseFloat(v);
		},

		is: function (el, ss) {
			if (typeof el == "string") {
				el = document.getElementById(el);
			}
			var isArray = Ext.isArray(el);
			var result = Ext.DomQuery.filter(isArray ? el : [el], ss);
			return isArray ? (result.length == el.length) : (result.length > 0);
		},

		filter: function (els, ss, nonMatches) {
			ss = ss.replace(trimRe, "");
			if (!simpleCache[ss]) {
				simpleCache[ss] = Ext.DomQuery.compile(ss, "simple");
			}
			var result = simpleCache[ss](els);
			return nonMatches ? quickDiff(result, els) : result;
		},

		matchers: [{
			re: /^\.([\w-]+)/,
			select: 'n = byClassName(n, null, " {1} ");'
		}, {
			re: /^\:([\w-]+)(?:\(((?:[^\s>\/]*|.*?))\))?/,
			select: 'n = byPseudo(n, "{1}", "{2}");'
		}, {
			re: /^(?:([\[\{])(?:@)?([\w-]+)\s?(?:(=|.=)\s?['"]?(.*?)["']?)?[\]\}])/,
			select: 'n = byAttribute(n, "{2}", "{4}", "{3}", "{1}");'
		}, {
			re: /^#([\w-]+)/,
			select: 'n = byId(n, null, "{1}");'
		}, {
			re: /^@([\w-]+)/,
			select: 'return {firstChild:{nodeValue:attrValue(n, "{1}")}};'
		}
        ],

		operators: {
			"=": function (a, v) {
				return a == v;
			},
			"!=": function (a, v) {
				return a != v;
			},
			"^=": function (a, v) {
				return a && a.substr(0, v.length) == v;
			},
			"$=": function (a, v) {
				return a && a.substr(a.length - v.length) == v;
			},
			"*=": function (a, v) {
				return a && a.indexOf(v) !== -1;
			},
			"%=": function (a, v) {
				return (a % v) == 0;
			},
			"|=": function (a, v) {
				return a && (a == v || a.substr(0, v.length + 1) == v + '-');
			},
			"~=": function (a, v) {
				return a && (' ' + a + ' ').indexOf(' ' + v + ' ') != -1;
			}
		},

		pseudos: {
			"first-child": function (c) {
				var r = [], ri = -1, n;
				for (var i = 0, ci; ci = n = c[i]; i++) {
					while ((n = n.previousSibling) && n.nodeType != 1) {
					}
					if (!n) {
						r[++ri] = ci;
					}
				}
				return r;
			},

			"last-child": function (c) {
				var r = [], ri = -1, n;
				for (var i = 0, ci; ci = n = c[i]; i++) {
					while ((n = n.nextSibling) && n.nodeType != 1) {
					}
					if (!n) {
						r[++ri] = ci;
					}
				}
				return r;
			},

			"nth-child": function (c, a) {
				var r = [], ri = -1;
				var m = nthRe.exec(a == "even" && "2n" || a == "odd" && "2n+1" || !nthRe2.test(a) && "n+" + a || a);
				var f = (m[1] || 1) - 0, l = m[2] - 0;
				for (var i = 0, n; n = c[i]; i++) {
					var pn = n.parentNode;
					if (batch != pn._batch) {
						var j = 0;
						for (var cn = pn.firstChild; cn; cn = cn.nextSibling) {
							if (cn.nodeType == 1) {
								cn.nodeIndex = ++j;
							}
						}
						pn._batch = batch;
					}
					if (f == 1) {
						if (l == 0 || n.nodeIndex == l) {
							r[++ri] = n;
						}
					} else if ((n.nodeIndex + l) % f == 0) {
						r[++ri] = n;
					}
				}

				return r;
			},

			"only-child": function (c) {
				var r = [], ri = -1; ;
				for (var i = 0, ci; ci = c[i]; i++) {
					if (!prev(ci) && !next(ci)) {
						r[++ri] = ci;
					}
				}
				return r;
			},

			"empty": function (c) {
				var r = [], ri = -1;
				for (var i = 0, ci; ci = c[i]; i++) {
					var cns = ci.childNodes, j = 0, cn, empty = true;
					while (cn = cns[j]) {
						++j;
						if (cn.nodeType == 1 || cn.nodeType == 3) {
							empty = false;
							break;
						}
					}
					if (empty) {
						r[++ri] = ci;
					}
				}
				return r;
			},

			"contains": function (c, v) {
				var r = [], ri = -1;
				for (var i = 0, ci; ci = c[i]; i++) {
					if ((ci.textContent || ci.innerText || '').indexOf(v) != -1) {
						r[++ri] = ci;
					}
				}
				return r;
			},

			"nodeValue": function (c, v) {
				var r = [], ri = -1;
				for (var i = 0, ci; ci = c[i]; i++) {
					if (ci.firstChild && ci.firstChild.nodeValue == v) {
						r[++ri] = ci;
					}
				}
				return r;
			},

			"checked": function (c) {
				var r = [], ri = -1;
				for (var i = 0, ci; ci = c[i]; i++) {
					if (ci.checked == true) {
						r[++ri] = ci;
					}
				}
				return r;
			},

			"not": function (c, ss) {
				return Ext.DomQuery.filter(c, ss, true);
			},

			"any": function (c, selectors) {
				var ss = selectors.split('|');
				var r = [], ri = -1, s;
				for (var i = 0, ci; ci = c[i]; i++) {
					for (var j = 0; s = ss[j]; j++) {
						if (Ext.DomQuery.is(ci, s)) {
							r[++ri] = ci;
							break;
						}
					}
				}
				return r;
			},

			"odd": function (c) {
				return this["nth-child"](c, "odd");
			},

			"even": function (c) {
				return this["nth-child"](c, "even");
			},

			"nth": function (c, a) {
				return c[a - 1] || [];
			},

			"first": function (c) {
				return c[0] || [];
			},

			"last": function (c) {
				return c[c.length - 1] || [];
			},

			"has": function (c, ss) {
				var s = Ext.DomQuery.select;
				var r = [], ri = -1;
				for (var i = 0, ci; ci = c[i]; i++) {
					if (s(ss, ci).length > 0) {
						r[++ri] = ci;
					}
				}
				return r;
			},

			"next": function (c, ss) {
				var is = Ext.DomQuery.is;
				var r = [], ri = -1;
				for (var i = 0, ci; ci = c[i]; i++) {
					var n = next(ci);
					if (n && is(n, ss)) {
						r[++ri] = ci;
					}
				}
				return r;
			},

			"prev": function (c, ss) {
				var is = Ext.DomQuery.is;
				var r = [], ri = -1;
				for (var i = 0, ci; ci = c[i]; i++) {
					var n = prev(ci);
					if (n && is(n, ss)) {
						r[++ri] = ci;
					}
				}
				return r;
			}
		}
	};
} ();

Ext.query = Ext.DomQuery.select;

Ext.util.Observable = function () {

	if (this.listeners) {
		this.on(this.listeners);
		delete this.listeners;
	}
};

Ext.util.Observable.prototype = {
	useProfile: true,
	//enabledAjaxEvents: {},

	fireEvent: function () {
		if (this.eventsSuspended !== true) {
			var ce = this.events[arguments[0].toLowerCase()];
			if (typeof ce == "object") {
				return ce.fire.apply(ce, Array.prototype.slice.call(arguments, 1));
			}
		}
		return true;
	},

	filterOptRe: /^(?:scope|delay|buffer|single)$/,

	addListener: function (eventName, fn, scope, o) {
		if (typeof eventName == "object") {
			o = eventName;
			for (var e in o) {
				if (this.filterOptRe.test(e)) {
					continue;
				}
				if (typeof o[e] == "function") {
					this.addListener(e, o[e], o.scope, o);
				} else {
					this.addListener(e, o[e].fn, o[e].scope, o[e]);
				}
			}
			return;
		}
		o = (!o || typeof o == "boolean") ? {} : o;
		eventName = eventName.toLowerCase();
		var ce = this.events[eventName] || true;
		if (typeof ce == "boolean") {
			ce = new Ext.util.Event(this, eventName);
			this.events[eventName] = ce;
		}
		ce.addListener(fn, scope, o);
	},

	removeListener: function (eventName, fn, scope) {
		var ce = this.events[eventName.toLowerCase()];
		if (typeof ce == "object") {
			ce.removeListener(fn, scope);
		}
	},

	purgeListeners: function () {
		for (var evt in this.events) {
			if (typeof this.events[evt] == "object") {
				this.events[evt].clearListeners();
			}
		}
	},

	relayEvents: function (o, events) {
		var createHandler = function (ename) {
			return function () {
				return this.fireEvent.apply(this, Ext.combine(ename, Array.prototype.slice.call(arguments, 0)));
			};
		};
		for (var i = 0, len = events.length; i < len; i++) {
			var ename = events[i];
			if (!this.events[ename]) { this.events[ename] = true; };
			o.on(ename, createHandler(ename), this);
		}
	},

	addEvents: function (o) {
		if (!this.events) {
			this.events = {};
		}
		if (!this.enabledAjaxEvents) {
			this.enabledAjaxEvents = {};
		}
		if (typeof o == 'string') {
			for (var i = 0, a = arguments, v; v = a[i]; i++) {
				if (!this.events[a[i]]) {
					this.events[a[i]] = true;
				}
				if (!this.enabledAjaxEvents[a[i]]) {
					this.enabledAjaxEvents[a[i]] = true;
				}
			}
		} else {
			Ext.applyIf(this.events, o);
		}
	},

	suspendAjaxEvents: function () {
		var args = arguments;
		//var enabledAjaxEvents = this.enabledAjaxEvents;
		if (args.length != 0 && this.enabledAjaxEvents.hasOwnProperty(args[0])) {
			this.enabledAjaxEvents[args[0]] = false;
			return;
		}
		for (var eventName in this.enabledAjaxEvents) {
			var event = this.enabledAjaxEvents[eventName];
			this.enabledAjaxEvents[eventName] = false;
		}
	},

	resumeAjaxEvents: function () {
		var args = arguments;
		//var enabledAjaxEvents = this.enabledAjaxEvents;
		if (args.length != 0 && this.enabledAjaxEvents.hasOwnProperty(args[0])) {
			this.enabledAjaxEvents[args[0]] = true;
			return;
		}
		for (var eventName in this.enabledAjaxEvents) {
			this.enabledAjaxEvents[eventName] = true;
		}
	},

	hasListener: function (eventName) {
		var e = this.events[eventName];
		return typeof e == "object" && e.listeners.length > 0;
	},

	suspendEvents: function () {
		if (this.suspendEventsCallCounter == undefined) {
			this.suspendEventsCallCounter = 0;
		}
		this.suspendEventsCallCounter++;
		this.eventsSuspended = true;
	},

	resumeEvents: function () {
		if (this.suspendEventsCallCounter > 0) {
			this.suspendEventsCallCounter--;
		}
		if ((!this.suspendEventsCallCounter) || (this.suspendEventsCallCounter < 1)) {
			this.eventsSuspended = false;
		}
	},

	getMethodEvent: function (method) {
		if (!this.methodEvents) {
			this.methodEvents = {};
		}
		var e = this.methodEvents[method];
		if (!e) {
			e = {};
			this.methodEvents[method] = e;

			e.originalFn = this[method];
			e.methodName = method;
			e.before = [];
			e.after = [];

			var returnValue, v, cancel;
			var obj = this;

			var makeCall = function (fn, scope, args) {
				if ((v = fn.apply(scope || obj, args)) !== undefined) {
					if (typeof v === 'object') {
						if (v.returnValue !== undefined) {
							returnValue = v.returnValue;
						} else {
							returnValue = v;
						}
						if (v.cancel === true) {
							cancel = true;
						}
					} else if (v === false) {
						cancel = true;
					} else {
						returnValue = v;
					}
				}
			}

			this[method] = function () {
				returnValue = v = undefined; cancel = false;
				var args = Array.prototype.slice.call(arguments, 0);
				for (var i = 0, len = e.before.length; i < len; i++) {
					makeCall(e.before[i].fn, e.before[i].scope, args);
					if (cancel) {
						return returnValue;
					}
				}

				if ((v = e.originalFn.apply(obj, args)) !== undefined) {
					returnValue = v;
				}

				for (var i = 0, len = e.after.length; i < len; i++) {
					makeCall(e.after[i].fn, e.after[i].scope, args);
					if (cancel) {
						return returnValue;
					}
				}
				return returnValue;
			};
		}
		return e;
	},

	beforeMethod: function (method, fn, scope) {
		var e = this.getMethodEvent(method);
		e.before.push({ fn: fn, scope: scope });
	},

	afterMethod: function (method, fn, scope) {
		var e = this.getMethodEvent(method);
		e.after.push({ fn: fn, scope: scope });
	},

	removeMethodListener: function (method, fn, scope) {
		var e = this.getMethodEvent(method);
		for (var i = 0, len = e.before.length; i < len; i++) {
			if (e.before[i].fn == fn && e.before[i].scope == scope) {
				e.before.splice(i, 1);
				return;
			}
		}
		for (var i = 0, len = e.after.length; i < len; i++) {
			if (e.after[i].fn == fn && e.after[i].scope == scope) {
				e.after.splice(i, 1);
				return;
			}
		}
	},

	callPageMethod: function (name, extraParams, formProxy) {
		if (extraParams.extraParams) {
			Ext.apply(extraParams, extraParams.extraParams);
			extraParams.extraParams = undefined;
		}
		var eventMask = extraParams.eventMask;
		delete extraParams.eventMask;
		var isUpload = extraParams.isUpload;
		delete extraParams.isUpload;
		var params = extraParams || {};
		Ext.AjaxEvent.request({
			extraParams: params,
			formProxyArg: formProxy || 'htmlForm',
			control: this,
			action: name,
			eventMask: eventMask,
			isUpload: isUpload,
			eventType: "pagemethod",
			viewStateMode: params.viewStateMode || 'include'
		});
	},

	setCustomData: function (key, data) {
		var customDataFieldEl = Ext.get('customDataField');
		var customDataValue = '';
		if (customDataFieldEl) {
			customDataValue = Ext.decode(customDataFieldEl.dom.value);
			if (!customDataValue.tempData) {
				customDataValue.tempData = {};
			} else {
				customDataValue.tempData = Ext.decode(customDataValue.tempData);
			}
			var id = this.id;
			if (!customDataValue.tempData[id]) {
				customDataValue.tempData[id] = {};
			}
			customDataValue.tempData[id][key] = data;
			customDataValue.tempData = Ext.encode(customDataValue.tempData);
			customDataFieldEl.dom.value = Ext.encode(customDataValue);
		}
	},

	getCustomData: function (key) {
		var customDataFieldEl = Ext.get('customDataField');
		var customDataValue = '';
		if (customDataFieldEl) {
			customDataValue = Ext.decode(customDataFieldEl.dom.value);
			if (!customDataValue.tempData) {
				customDataValue.tempData = {};
			} else {
				customDataValue.tempData = Ext.decode(customDataValue.tempData);
			}
			var id = this.id;
			if (!customDataValue.tempData[id]) {
				customDataValue.tempData[id] = {};
			}
			return customDataValue.tempData[id][key];
		}
	},

	setProfileData: function (key, data) {
		if (this.designMode || !this.useProfile) {
			return;
		}
		var profileData = window.profileData;
		if (profileData) {
			profileData.setData(this.id, key, data)
		}
	}
};

Ext.util.Observable.prototype.on = Ext.util.Observable.prototype.addListener;

Ext.util.Observable.prototype.un = Ext.util.Observable.prototype.removeListener;

Ext.util.Observable.capture = function (o, fn, scope) {
	o.fireEvent = o.fireEvent.createInterceptor(fn, scope);
};

Ext.util.Observable.releaseCapture = function (o) {
	o.fireEvent = Ext.util.Observable.prototype.fireEvent;
};

(function () {

	var createBuffered = function (h, o, scope) {
		var task = new Ext.util.DelayedTask();
		return function () {
			task.delay(o.buffer, h, scope, Array.prototype.slice.call(arguments, 0));
		};
	};

	var createSingle = function (h, e, fn, scope) {
		return function () {
			e.removeListener(fn, scope);
			return h.apply(scope, arguments);
		};
	};

	var createDelayed = function (h, o, scope) {
		return function () {
			var args = Array.prototype.slice.call(arguments, 0);
			setTimeout(function () {
				h.apply(scope, args);
			}, o.delay || 10);
		};
	};

	Ext.util.Event = function (obj, name) {
		this.name = name;
		this.obj = obj;
		this.listeners = [];
	};

	Ext.util.Event.prototype = {
		addListener: function (fn, scope, options) {
			scope = scope || this.obj;
			if (!this.isListening(fn, scope)) {
				var l = this.createListener(fn, scope, options);
				if (!this.firing) {
					this.listeners.push(l);
				} else {
					this.listeners = this.listeners.slice(0);
					this.listeners.push(l);
				}
			}
		},

		createListener: function (fn, scope, o) {
			o = o || {};
			scope = scope || this.obj;
			var l = { fn: fn, scope: scope, options: o };
			var h = fn;
			if (o.delay) {
				h = createDelayed(h, o, scope);
			}
			if (o.single) {
				h = createSingle(h, this, fn, scope);
			}
			if (o.buffer) {
				h = createBuffered(h, o, scope);
			}
			l.fireFn = h;
			return l;
		},

		findListener: function (fn, scope) {
			scope = scope || this.obj;
			var ls = this.listeners;
			for (var i = 0, len = ls.length; i < len; i++) {
				var l = ls[i];
				if (l.fn == fn && l.scope == scope) {
					return i;
				}
			}
			return -1;
		},

		isListening: function (fn, scope) {
			return this.findListener(fn, scope) != -1;
		},

		removeListener: function (fn, scope) {
			var index;
			if ((index = this.findListener(fn, scope)) != -1) {
				if (!this.firing) {
					this.listeners.splice(index, 1);
				} else {
					this.listeners = this.listeners.slice(0);
					this.listeners.splice(index, 1);
				}
				return true;
			}
			return false;
		},

		clearListeners: function () {
			this.listeners = [];
		},

		fire: function () {
			var ls = this.listeners, len = ls.length;
			if (len > 0) {
				this.firing = true;
				var args = Array.prototype.slice.call(arguments, 0);
				for (var i = 0; i < len; i++) {
					var l = ls[i];
					var scope = l.scope || this.obj || window;
					if (typeof scope == 'string') {
						scope = window[scope];
					}
					if (l.fireFn.apply(scope, arguments) === false) {
						this.firing = false;
						return false;
					}
				}
				this.firing = false;
			}
			return true;
		}
	};
})();

/**
* @class Ext.EventManager
* Registers event handlers that want to receive a normalized EventObject instead of the standard browser event and provides
* several useful events directly.
* See {@link Ext.EventObject} for more details on normalized event objects.
* @singleton
*/
Ext.EventManager = function () {
	var docReadyEvent, docReadyProcId, docReadyState = false;
	var resizeEvent, resizeTask, textEvent, textSize;
	var E = Ext.lib.Event;
	var D = Ext.lib.Dom;
	// fix parser confusion
	var xname = 'Ex' + 't';

	var elHash = {};

	var addListener = function (el, ename, fn, wrap, scope) {
		var id = Ext.id(el);
		if (!elHash[id]) {
			elHash[id] = {};
		}
		var es = elHash[id];
		if (!es[ename]) {
			es[ename] = [];
		}
		var ls = es[ename];
		ls.push({
			id: id,
			ename: ename,
			fn: fn,
			wrap: wrap,
			scope: scope
		});

		E.on(el, ename, wrap);

		if (ename == "mousewheel" && el.addEventListener) { // workaround for jQuery
			el.addEventListener("DOMMouseScroll", wrap, false);
			E.on(window, 'unload', function () {
				el.removeEventListener("DOMMouseScroll", wrap, false);
			});
		}
		// fix stopped mousedowns on the document
		if (ename == "mousedown" && (el == document || el == document.body)) {
			Ext.EventManager.stoppedMouseDownEvent.addListener(wrap);
		}
	}

	var removeListener = function (el, ename, fn, scope) {
		el = Ext.getDom(el);

		var id = Ext.id(el), es = elHash[id], wrap;
		if (es) {
			var ls = es[ename], l;
			if (ls) {
				for (var i = 0, len = ls.length; i < len; i++) {
					l = ls[i];
					if (l.fn == fn && (!scope || l.scope == scope)) {
						wrap = l.wrap;
						E.un(el, ename, wrap);
						ls.splice(i, 1);
						break;
					}
				}
			}
		}
		if (ename == "mousewheel" && el.addEventListener && wrap) {
			el.removeEventListener("DOMMouseScroll", wrap, false);
		}
		// fix stopped mousedowns on the document
		if (ename == "mousedown" && (el == document || el == document.body) && wrap) {
			Ext.EventManager.stoppedMouseDownEvent.removeListener(wrap);
		}
	}

	var removeAll = function (el) {
		el = Ext.getDom(el);
		var id = Ext.id(el), es = elHash[id], ls;
		if (es) {
			for (var ename in es) {
				if (es.hasOwnProperty(ename)) {
					ls = es[ename];
					for (var i = 0, len = ls.length; i < len; i++) {
						E.un(el, ename, ls[i].wrap);
						ls[i] = null;
					}
				}
				es[ename] = null;
			}
			delete elHash[id];
		}
	}

	var fireDocReady = function () {

		docReadyState = true;
		if (Ext.isGecko) {
			document.removeEventListener("DOMContentLoaded", fireDocReady, false);
		}

		if (docReadyProcId) {
			clearInterval(docReadyProcId);
			docReadyProcId = null;
		}

		if (docReadyEvent && !Ext.isReady) {
			Ext.isReady = true;
			//treat as an async call, so the event handler returns immediately.
			if (Ext.isWebKit) {
				var getWindowSize = function() {
					var screen = window.screen;
					var needResizeByWidth =
						(window.screenLeft + window.outerWidth > screen.availLeft + screen.availWidth);
					var needResizeByHeight =
						(window.screenTop + window.outerHeight > screen.availTop + screen.availHeight);
					return {
						needResize: (needResizeByHeight || needResizeByWidth),
						width: needResizeByWidth ? screen.availWidth : window.outerWidth,
						height: needResizeByHeight ? screen.availHeight : window.outerHeight
					};
				}
				var resizeWindow = function() {
					var size = getWindowSize();
					if (size.needResize) {
						window.resizeTo(size.width, size.height);
					}
					return size.needResize;
				}
				if (!resizeWindow()) {
					Ext.EventManager.on(window, "resize", function() {
						resizeWindow();
					}, this, {single: true});
					var offsetWidth = window.outerWidth - window.innerWidth;
					var offsetHeight = window.outerHeight - window.innerHeight;
					if (window.startWidth && window.startHeight) {
						window.resizeTo(window.startWidth + offsetWidth, window.startHeight + offsetHeight);
					}
				}
			}
			(function () {
				docReadyEvent.fire();
				docReadyEvent.clearListeners();
			}).defer(1);

		}
	};

	var initDocReady = function () {
		docReadyEvent = new Ext.util.Event();

		if (Ext.isReady) { return; }

		E.on(window, 'load', fireDocReady);

		if (Ext.isGecko) {
			document.addEventListener('DOMContentLoaded', fireDocReady, false);
		}
		else if (Ext.isIE) {

			document.onreadystatechange = function () {

				if (document.readyState == 'complete') {
					fireDocReady();
					document.onreadystatechange = null;
				}
			};

			//Use readystatechange as primary detection mechanism for an iframe

			/* notes:
			This:

			var node = document.createElement('p')  or document.documentElement
			node.doScroll('left');

			'doScroll' will NOT work in a IFRAME/FRAMESET.
			The method succeeds but, a DOM query done immediately after -- FAILS.

			*/

			if (window == top) {  //non-frames only
				var doScrollChk = function () {
					try {
						document.documentElement.doScroll('left');
						Ext.isReady || fireDocReady();

					} catch (e) {
						Ext.isReady || setTimeout(doScrollChk, 5);
						return;
					}
				};
				doScrollChk();
			}

		}
		else if (Ext.isOpera) {
			/* Notes:
			Special treatment MAY be needed here because CSS rules are NOT QUITE
			available after DOMContentLoaded is raised.
			*/
			var styles;
			document.addEventListener('DOMContentLoaded', function () {
				if (!Ext.isReady) {
					styles || (styles = Ext.query('style, link[rel=stylesheet]'));
					if (styles.length != document.styleSheets.length) {
						setTimeout(arguments.callee, 5);
						return;
					}
					fireDocReady();
				}
				document.removeEventListener("DOMContentLoaded", arguments.callee, false);

			}, false);

		}
		else if (Ext.isSafari) {  //Webkits (Konqueror, Safari, Chrome)

			/* Notes:
			Webkit has two different readystates for a 'loaded' state:
			'loaded' for non-frames
			'complete' for frames

			In a frame, onload fires just before readystate changes to 'complete'
			*/
			var stateRe = /complete|loaded/i;

			(function () {
				if (stateRe.test(document.readyState)) {
					fireDocReady();
					return;
				}
				setTimeout(arguments.callee, 5);
			})();
		}
	};

	var createBuffered = function (h, o) {
		var task = new Ext.util.DelayedTask(h);
		return function (e) {
			// create new event object impl so new events don't wipe out properties
			e = new Ext.EventObjectImpl(e);
			task.delay(o.buffer, h, null, [e]);
		};
	};

	var createSingle = function (h, el, ename, fn, scope) {
		return function (e) {
			Ext.EventManager.removeListener(el, ename, fn, scope);
			h(e);
		};
	};

	var createDelayed = function (h, o) {
		return function (e) {
			// create new event object impl so new events don't wipe out properties
			e = new Ext.EventObjectImpl(e);
			setTimeout(function () {
				h(e);
			}, o.delay || 10);
		};
	};

	var listen = function (element, ename, opt, fn, scope) {
		var o = (!opt || typeof opt == "boolean") ? {} : opt;
		fn = fn || o.fn; scope = scope || o.scope;
		var el = Ext.getDom(element);
		if (!el) {
			throw "Ошибка прослушивания \"" + ename + '\". Элемент "' + element + '" не существует.';
		}
		var h = function (e) {
			// prevent errors while unload occurring
			if (!window[xname]) {
				return;
			}
			e = Ext.EventObject.setEvent(e);
			var t;
			if (o.delegate) {
				t = e.getTarget(o.delegate, el);
				if (!t) {
					return;
				}
			} else {
				t = e.target;
			}
			if (o.stopEvent === true) {
				e.stopEvent();
			}
			if (o.preventDefault === true) {
				e.preventDefault();
			}
			if (o.stopPropagation === true) {
				e.stopPropagation();
			}

			if (stopBrowserEvents === true && e.browserEvent) {
				if (e.type == 'keyup' || e.type == 'keydown' || e.type == 'keypress') {
					return;
				}
			}

			if (o.normalized === false) {
				e = e.browserEvent;
			}

			fn.call(scope || el, e, t, o);
		};
		if (o.delay) {
			h = createDelayed(h, o);
		}
		if (o.single) {
			h = createSingle(h, el, ename, fn, scope);
		}
		if (o.buffer) {
			h = createBuffered(h, o);
		}

		addListener(el, ename, fn, h, scope);
		return h;
	};

	var suspendBrowserEvents = function () {
		stopBrowserEvents = true;
	};

	var resumeBrowserEvents = function () {
		stopBrowserEvents = false;
	};

	var stopBrowserEvents = false;
	var propRe = /^(?:scope|delay|buffer|single|stopEvent|preventDefault|stopPropagation|normalized|args|delegate)$/;
	var pub = {

		suspendBrowserEvents: function () {
			return suspendBrowserEvents();
		},

		resumeBrowserEvents: function () {
			return resumeBrowserEvents();
		},

		/**
		* Appends an event handler to an element.  The shorthand version {@link #on} is equivalent.  Typically you will
		* use {@link Ext.Element#addListener} directly on an Element in favor of calling this version.
		* @param {String/HTMLElement} el The html element or id to assign the event handler to
		* @param {String} eventName The type of event to listen for
		* @param {Function} handler The handler function the event invokes This function is passed
		* the following parameters:<ul>
		* <li>evt : EventObject<div class="sub-desc">The {@link Ext.EventObject EventObject} describing the event.</div></li>
		* <li>t : Element<div class="sub-desc">The {@link Ext.Element Element} which was the target of the event.
		* Note that this may be filtered by using the <tt>delegate</tt> option.</div></li>
		* <li>o : Object<div class="sub-desc">The options object from the addListener call.</div></li>
		* </ul>
		* @param {Object} scope (optional) The scope in which to execute the handler
		* function (the handler function's "this" context)
		* @param {Object} options (optional) An object containing handler configuration properties.
		* This may contain any of the following properties:<ul>
		* <li>scope {Object} : The scope in which to execute the handler function. The handler function's "this" context.</li>
		* <li>delegate {String} : A simple selector to filter the target or look for a descendant of the target</li>
		* <li>stopEvent {Boolean} : True to stop the event. That is stop propagation, and prevent the default action.</li>
		* <li>preventDefault {Boolean} : True to prevent the default action</li>
		* <li>stopPropagation {Boolean} : True to prevent event propagation</li>
		* <li>normalized {Boolean} : False to pass a browser event to the handler function instead of an Ext.EventObject</li>
		* <li>delay {Number} : The number of milliseconds to delay the invocation of the handler after te event fires.</li>
		* <li>single {Boolean} : True to add a handler to handle just the next firing of the event, and then remove itself.</li>
		* <li>buffer {Number} : Causes the handler to be scheduled to run in an {@link Ext.util.DelayedTask} delayed
		* by the specified number of milliseconds. If the event fires again within that time, the original
		* handler is <em>not</em> invoked, but the new handler is scheduled in its place.</li>
		* </ul><br>
		* <p>See {@link Ext.Element#addListener} for examples of how to use these options.</p>
		*/
		addListener: function (element, eventName, fn, scope, options) {
			if (typeof eventName == "object") {
				var o = eventName;
				for (var e in o) {
					if (propRe.test(e)) {
						continue;
					}
					if (typeof o[e] == "function") {
						// shared options
						listen(element, e, o, o[e], o.scope);
					} else {
						// individual options
						listen(element, e, o[e]);
					}
				}
				return;
			}
			return listen(element, eventName, options, fn, scope);
		},

		/**
		* Removes an event handler from an element.  The shorthand version {@link #un} is equivalent.  Typically
		* you will use {@link Ext.Element#removeListener} directly on an Element in favor of calling this version.
		* @param {String/HTMLElement} el The id or html element from which to remove the event
		* @param {String} eventName The type of event
		* @param {Function} fn The handler function to remove
		*/
		removeListener: function (element, eventName, fn, scope) {
			return removeListener(element, eventName, fn, scope);
		},

		/**
		* Removes all event handers from an element.  Typically you will use {@link Ext.Element#removeAllListeners}
		* directly on an Element in favor of calling this version.
		* @param {String/HTMLElement} el The id or html element from which to remove the event
		*/
		removeAll: function (element) {
			return removeAll(element);
		},

		/**
		* Fires when the document is ready (before onload and before images are loaded). Can be
		* accessed shorthanded as Ext.onReady().
		* @param {Function} fn The method the event invokes
		* @param {Object} scope (optional) An object that becomes the scope of the handler
		* @param {boolean} options (optional) An object containing standard {@link #addListener} options
		*/
		onDocumentReady: function (fn, scope, options) {
			if (!docReadyEvent) {
				initDocReady();
			}

			if (docReadyState || Ext.isReady) {
				//onReady has already fired, so just execute this block when presented
				//permitting multiple onReady blocks
				options || (options = {});
				if (options.delay) {
					fn.defer(options.delay, scope);
				} else {
					fn.call(scope);
				}
			} else {
				docReadyEvent.addListener(fn, scope, options);
			}
		},

		// private
		doResizeEvent: function () {
			resizeEvent.fire(D.getViewWidth(), D.getViewHeight());
		},

		/**
		* Fires when the window is resized and provides resize event buffering (50 milliseconds), passes new viewport width and height to handlers.
		* @param {Function} fn        The method the event invokes
		* @param {Object}   scope    An object that becomes the scope of the handler
		* @param {boolean}  options
		*/
		onWindowResize: function (fn, scope, options) {
			if (!resizeEvent) {
				resizeEvent = new Ext.util.Event();
				resizeTask = new Ext.util.DelayedTask(this.doResizeEvent);
				E.on(window, "resize", this.fireWindowResize, this);
			}
			resizeEvent.addListener(fn, scope, options);
		},

		// exposed only to allow manual firing
		fireWindowResize: function () {
			if (resizeEvent) {
				if ((Ext.isIE || Ext.isAir) && resizeTask) {
					resizeTask.delay(50);
				} else {
					resizeEvent.fire(D.getViewWidth(), D.getViewHeight());
				}
			}
		},

		/**
		* Fires when the user changes the active text size. Handler gets called with 2 params, the old size and the new size.
		* @param {Function} fn        The method the event invokes
		* @param {Object}   scope    An object that becomes the scope of the handler
		* @param {boolean}  options
		*/
		onTextResize: function (fn, scope, options) {
			if (!textEvent) {
				textEvent = new Ext.util.Event();
				var textEl = new Ext.Element(document.createElement('div'));
				textEl.dom.className = 'x-text-resize';
				textEl.dom.innerHTML = 'X';
				textEl.appendTo(document.body);
				textSize = textEl.dom.offsetHeight;
				setInterval(function () {
					if (textEl.dom.offsetHeight != textSize) {
						textEvent.fire(textSize, textSize = textEl.dom.offsetHeight);
					}
				}, this.textResizeInterval);
			}
			textEvent.addListener(fn, scope, options);
		},

		/**
		* Removes the passed window resize listener.
		* @param {Function} fn        The method the event invokes
		* @param {Object}   scope    The scope of handler
		*/
		removeResizeListener: function (fn, scope) {
			if (resizeEvent) {
				resizeEvent.removeListener(fn, scope);
			}
		},

		// private
		fireResize: function () {
			if (resizeEvent) {
				resizeEvent.fire(D.getViewWidth(), D.getViewHeight());
			}
		},

		/**
		* Url used for onDocumentReady with using SSL (defaults to Ext.SSL_SECURE_URL)
		*/
		ieDeferSrc: false,

		/**
		* The frequency, in milliseconds, to check for text resize events (defaults to 50)
		*/
		textResizeInterval: 50
	};
	/**
	* Appends an event handler to an element.  Shorthand for {@link #addListener}.
	* @param {String/HTMLElement} el The html element or id to assign the event handler to
	* @param {String} eventName The type of event to listen for
	* @param {Function} handler The handler function the event invokes
	* @param {Object} scope (optional) The scope in which to execute the handler
	* function (the handler function's "this" context)
	* @param {Object} options (optional) An object containing standard {@link #addListener} options
	* @member Ext.EventManager
	* @method on
	*/
	pub.on = pub.addListener;
	/**
	* Removes an event handler from an element.  Shorthand for {@link #removeListener}.
	* @param {String/HTMLElement} el The id or html element from which to remove the event
	* @param {String} eventName The type of event
	* @param {Function} fn The handler function to remove
	* @return {Boolean} True if a listener was actually removed, else false
	* @member Ext.EventManager
	* @method un
	*/
	pub.un = pub.removeListener;

	pub.stoppedMouseDownEvent = new Ext.util.Event();
	return pub;
} ();

/**
* Fires when the document is ready (before onload and before images are loaded).  Shorthand of {@link Ext.EventManager#onDocumentReady}.
* @param {Function} fn        The method the event invokes
* @param {Object}   scope    An  object that becomes the scope of the handler
* @param {boolean}  override If true, the obj passed in becomes
*                             the execution scope of the listener
* @member Ext
* @method onReady
*/
Ext.onReady = Ext.EventManager.onDocumentReady;

// Initialize doc classes
(function () {
	var initExtCss = function () {
		// find the body element
		var bd = document.body || document.getElementsByTagName('body')[0];
		if (!bd) { return false; }
		var cls = [' ',
                Ext.isIE ? "ext-ie " + (Ext.isIE6 ? 'ext-ie6' : (Ext.isIE7 ? 'ext-ie7' : ''))
                : Ext.isGecko ? "ext-gecko " + (Ext.isGecko2 ? 'ext-gecko2' : 'ext-gecko3')
                : Ext.isOpera ? "ext-opera"
                : Ext.isSafari ? "ext-safari" : ""];
		if (Ext.isChrome9) {
			cls.push("ext-chrome9");
		}
		if (Ext.isMac) {
			cls.push("ext-mac");
		}
		if (Ext.isLinux) {
			cls.push("ext-linux");
		}
		if (Ext.isBorderBox) {
			cls.push('ext-border-box');
		}
		if (Ext.isStrict) { // add to the parent to allow for selectors like ".ext-strict .ext-ie"
			var p = bd.parentNode;
			if (p) {
				p.className += ' ext-strict';
			}
		}
		bd.className += cls.join(' ');
		return true;
	}

	if (!initExtCss()) {
		Ext.onReady(initExtCss);
	}
})();

/**
* @class Ext.EventObject
* EventObject exposes the Yahoo! UI Event functionality directly on the object
* passed to your event handler. It exists mostly for convenience. It also fixes the annoying null checks automatically to cleanup your code
* Example:
* <pre><code>
function handleClick(e){ // e is not a standard event object, it is a Ext.EventObject
e.preventDefault();
var target = e.getTarget();
...
}
var myDiv = Ext.get("myDiv");
myDiv.on("click", handleClick);
//or
Ext.EventManager.on("myDiv", 'click', handleClick);
Ext.EventManager.addListener("myDiv", 'click', handleClick);
</code></pre>
* @singleton
*/
Ext.EventObject = function () {

	var E = Ext.lib.Event;

	// safari keypress events for special keys return bad keycodes
	var safariKeys = {
		3: 13, // enter
		63234: 37, // left
		63235: 39, // right
		63232: 38, // up
		63233: 40, // down
		63276: 33, // page up
		63277: 34, // page down
		63272: 46, // delete
		63273: 36, // home
		63275: 35  // end
	};

	// normalize button clicks
	var btnMap = Ext.isIE ? { 1: 0, 4: 1, 2: 2} : { 0: 0, 1: 1, 2: 2 };

	Ext.EventObjectImpl = function (e) {
		if (e) {
			this.setEvent(e.browserEvent || e);
		}
	};

	Ext.EventObjectImpl.prototype = {
		/** The normal browser event */
		browserEvent: null,
		/** The button pressed in a mouse event */
		button: -1,
		/** True if the shift key was down during the event */
		shiftKey: false,
		/** True if the control key was down during the event */
		ctrlKey: false,
		/** True if the alt key was down during the event */
		altKey: false,

		/** Key constant @type Number */
		BACKSPACE: 8,
		/** Key constant @type Number */
		TAB: 9,
		/** Key constant @type Number */
		NUM_CENTER: 12,
		/** Key constant @type Number */
		ENTER: 13,
		/** Key constant @type Number */
		RETURN: 13,
		/** Key constant @type Number */
		SHIFT: 16,
		/** Key constant @type Number */
		CTRL: 17,
		CONTROL: 17, // legacy
		/** Key constant @type Number */
		ALT: 18,
		/** Key constant @type Number */
		PAUSE: 19,
		/** Key constant @type Number */
		CAPS_LOCK: 20,
		/** Key constant @type Number */
		ESC: 27,
		/** Key constant @type Number */
		SPACE: 32,
		/** Key constant @type Number */
		PAGE_UP: 33,
		PAGEUP: 33, // legacy
		/** Key constant @type Number */
		PAGE_DOWN: 34,
		PAGEDOWN: 34, // legacy
		/** Key constant @type Number */
		END: 35,
		/** Key constant @type Number */
		HOME: 36,
		/** Key constant @type Number */
		LEFT: 37,
		/** Key constant @type Number */
		UP: 38,
		/** Key constant @type Number */
		RIGHT: 39,
		/** Key constant @type Number */
		DOWN: 40,
		/** Key constant @type Number */
		PRINT_SCREEN: 44,
		/** Key constant @type Number */
		INSERT: 45,
		/** Key constant @type Number */
		DELETE: 46,
		/** Key constant @type Number */
		ZERO: 48,
		/** Key constant @type Number */
		ONE: 49,
		/** Key constant @type Number */
		TWO: 50,
		/** Key constant @type Number */
		THREE: 51,
		/** Key constant @type Number */
		FOUR: 52,
		/** Key constant @type Number */
		FIVE: 53,
		/** Key constant @type Number */
		SIX: 54,
		/** Key constant @type Number */
		SEVEN: 55,
		/** Key constant @type Number */
		EIGHT: 56,
		/** Key constant @type Number */
		NINE: 57,
		/** Key constant @type Number */
		A: 65,
		/** Key constant @type Number */
		B: 66,
		/** Key constant @type Number */
		C: 67,
		/** Key constant @type Number */
		D: 68,
		/** Key constant @type Number */
		E: 69,
		/** Key constant @type Number */
		F: 70,
		/** Key constant @type Number */
		G: 71,
		/** Key constant @type Number */
		H: 72,
		/** Key constant @type Number */
		I: 73,
		/** Key constant @type Number */
		J: 74,
		/** Key constant @type Number */
		K: 75,
		/** Key constant @type Number */
		L: 76,
		/** Key constant @type Number */
		M: 77,
		/** Key constant @type Number */
		N: 78,
		/** Key constant @type Number */
		O: 79,
		/** Key constant @type Number */
		P: 80,
		/** Key constant @type Number */
		Q: 81,
		/** Key constant @type Number */
		R: 82,
		/** Key constant @type Number */
		S: 83,
		/** Key constant @type Number */
		T: 84,
		/** Key constant @type Number */
		U: 85,
		/** Key constant @type Number */
		V: 86,
		/** Key constant @type Number */
		W: 87,
		/** Key constant @type Number */
		X: 88,
		/** Key constant @type Number */
		Y: 89,
		/** Key constant @type Number */
		Z: 90,
		/** Key constant @type Number */
		CONTEXT_MENU: 93,
		/** Key constant @type Number */
		NUM_ZERO: 96,
		/** Key constant @type Number */
		NUM_ONE: 97,
		/** Key constant @type Number */
		NUM_TWO: 98,
		/** Key constant @type Number */
		NUM_THREE: 99,
		/** Key constant @type Number */
		NUM_FOUR: 100,
		/** Key constant @type Number */
		NUM_FIVE: 101,
		/** Key constant @type Number */
		NUM_SIX: 102,
		/** Key constant @type Number */
		NUM_SEVEN: 103,
		/** Key constant @type Number */
		NUM_EIGHT: 104,
		/** Key constant @type Number */
		NUM_NINE: 105,
		/** Key constant @type Number */
		NUM_MULTIPLY: 106,
		/** Key constant @type Number */
		NUM_PLUS: 107,
		/** Key constant @type Number */
		NUM_MINUS: 109,
		/** Key constant @type Number */
		NUM_PERIOD: 110,
		/** Key constant @type Number */
		NUM_DIVISION: 111,
		/** Key constant @type Number */
		F1: 112,
		/** Key constant @type Number */
		F2: 113,
		/** Key constant @type Number */
		F3: 114,
		/** Key constant @type Number */
		F4: 115,
		/** Key constant @type Number */
		F5: 116,
		/** Key constant @type Number */
		F6: 117,
		/** Key constant @type Number */
		F7: 118,
		/** Key constant @type Number */
		F8: 119,
		/** Key constant @type Number */
		F9: 120,
		/** Key constant @type Number */
		F10: 121,
		/** Key constant @type Number */
		F11: 122,
		/** Key constant @type Number */
		F12: 123,

		/** @private */
		setEvent: function (e) {
			if (e == this || (e && e.browserEvent)) { // already wrapped
				return e;
			}
			this.browserEvent = e;
			if (e) {
				// normalize buttons
				this.button = e.button ? btnMap[e.button] : (e.which ? e.which - 1 : -1);
				if (e.type == 'click' && this.button == -1) {
					this.button = 0;
				}
				this.type = e.type;
				this.shiftKey = e.shiftKey;
				// mac metaKey behaves like ctrlKey
				this.ctrlKey = e.ctrlKey || e.metaKey;
				this.altKey = e.altKey;
				// in getKey these will be normalized for the mac
				this.keyCode = e.keyCode;
				this.charCode = e.charCode;
				// cache the target for the delayed and or buffered events
				this.target = E.getTarget(e);
				// same for XY
				this.xy = E.getXY(e);
			} else {
				this.button = -1;
				this.shiftKey = false;
				this.ctrlKey = false;
				this.altKey = false;
				this.keyCode = 0;
				this.charCode = 0;
				this.target = null;
				this.xy = [0, 0];
			}
			return this;
		},

		/**
		* Stop the event (preventDefault and stopPropagation)
		*/
		stopEvent: function () {
			if (this.browserEvent) {
				if (this.browserEvent.type == 'mousedown') {
					Ext.EventManager.stoppedMouseDownEvent.fire(this);
				}
				E.stopEvent(this.browserEvent);
			}
		},

		/**
		* Prevents the browsers default handling of the event.
		*/
		preventDefault: function () {
			if (this.browserEvent) {
				E.preventDefault(this.browserEvent);
			}
		},

		/** @private */
		isNavKeyPress: function () {
			var k = this.keyCode;
			k = Ext.isSafari ? (safariKeys[k] || k) : k;
			return (k >= 33 && k <= 40) || k == this.RETURN || k == this.TAB || k == this.ESC;
		},

		isSpecialKey: function () {
			var k = this.keyCode;
			return (this.type == 'keypress' && this.ctrlKey) || k == 9 || k == 13 || k == 40 || k == 27 ||
            (k == 16) || (k == 17) ||
            (k >= 18 && k <= 20) ||
            (k >= 33 && k <= 35) ||
            (k >= 36 && k <= 39) ||
            (k >= 44 && k <= 45);
		},

		/**
		* Cancels bubbling of the event.
		*/
		stopPropagation: function () {
			if (this.browserEvent) {
				if (this.browserEvent.type == 'mousedown') {
					Ext.EventManager.stoppedMouseDownEvent.fire(this);
				}
				E.stopPropagation(this.browserEvent);
			}
		},

		/**
		* Gets the character code for the event.
		* @return {Number}
		*/
		getCharCode: function () {
			return this.charCode || this.keyCode;
		},

		/**
		* Returns a normalized keyCode for the event.
		* @return {Number} The key code
		*/
		getKey: function () {
			var k = this.keyCode || this.charCode;
			return Ext.isSafari ? (safariKeys[k] || k) : k;
		},

		/**
		* Gets the x coordinate of the event.
		* @return {Number}
		*/
		getPageX: function () {
			return this.xy[0];
		},

		/**
		* Gets the y coordinate of the event.
		* @return {Number}
		*/
		getPageY: function () {
			return this.xy[1];
		},

		/**
		* Gets the time of the event.
		* @return {Number}
		*/
		getTime: function () {
			if (this.browserEvent) {
				return E.getTime(this.browserEvent);
			}
			return null;
		},

		/**
		* Gets the page coordinates of the event.
		* @return {Array} The xy values like [x, y]
		*/
		getXY: function () {
			return this.xy;
		},

		/**
		* Gets the target for the event.
		* @param {String} selector (optional) A simple selector to filter the target or look for an ancestor of the target
		* @param {Number/Mixed} maxDepth (optional) The max depth to
		search as a number or element (defaults to 10 || document.body)
		* @param {Boolean} returnEl (optional) True to return a Ext.Element object instead of DOM node
		* @return {HTMLelement}
		*/
		getTarget: function (selector, maxDepth, returnEl) {
			return selector ? Ext.fly(this.target).findParent(selector, maxDepth, returnEl) : (returnEl ? Ext.get(this.target) : this.target);
		},

		/**
		* Gets the related target.
		* @return {HTMLElement}
		*/
		getRelatedTarget: function () {
			if (this.browserEvent) {
				return E.getRelatedTarget(this.browserEvent);
			}
			return null;
		},

		/**
		* Normalizes mouse wheel delta across browsers
		* @return {Number} The delta
		*/
		getWheelDelta: function () {
			var e = this.browserEvent;
			var delta = 0;
			if (e.wheelDelta) { /* IE/Opera. */
				delta = e.wheelDelta / 120;
			} else if (e.detail) { /* Mozilla case. */
				delta = -e.detail / 3;
			}
			return delta;
		},

		/**
		* Returns true if the control, meta, shift or alt key was pressed during this event.
		* @return {Boolean}
		*/
		hasModifier: function () {
			return ((this.ctrlKey || this.altKey) || this.shiftKey) ? true : false;
		},

		/**
		* Returns true if the target of this event is a child of el.  If the target is el, it returns false.
		* Example usage:<pre><code>
		// Handle click on any child of an element
		Ext.getBody().on('click', function(e){
		if(e.within('some-el')){
		alert('Clicked on a child of some-el!');
		}
		});

		// Handle click directly on an element, ignoring clicks on child nodes
		Ext.getBodyodyodyodyody().on('click', function(e,t){
		if((t.id == 'some-el') && !e.within(t, true)){
		alert('Clicked directly on some-el!');
		}
		});
		</code></pre>
		* @param {Mixed} el The id, DOM element or Ext.Element to check
		* @param {Boolean} related (optional) true to test if the related target is within el instead of the target
		* @return {Boolean}
		*/
		within: function (el, related) {
			var t = this[related ? "getRelatedTarget" : "getTarget"]();
			return t && Ext.fly(el).contains(t);
		},

		withinExt: function (el, related) {
			var t = this[related ? "getRelatedTarget" : "getTarget"]();
			return t && (Ext.fly(el).contains(t) || Ext.get(el) == Ext.get(t));
		},

		getPoint: function () {
			return new Ext.lib.Point(this.xy[0], this.xy[1]);
		}
	};

	return new Ext.EventObjectImpl();
} ();

(function () {
	var D = Ext.lib.Dom;
	var E = Ext.lib.Event;
	var A = Ext.lib.Anim;

	var propCache = {};
	var camelRe = /(-[a-z])/gi;
	var camelFn = function (m, a) { return a.charAt(1).toUpperCase(); };
	var view = document.defaultView;

	Ext.Element = function (element, forceNew) {
		var dom = typeof element == "string" ?
            document.getElementById(element) : element;
		if (!dom) {
			return null;
		}
		var id = dom.id;
		if (forceNew !== true && id && Ext.Element.cache[id]) {
			return Ext.Element.cache[id];
		}
		this.dom = dom;
		this.id = id || Ext.id(dom);
	};

	var El = Ext.Element;

	El.prototype = {

		originalDisplay: "",

		visibilityMode: 1,

		defaultUnit: "px",

		setVisibilityMode: function (visMode) {
			this.visibilityMode = visMode;
			return this;
		},

		enableDisplayMode: function (display) {
			this.setVisibilityMode(El.DISPLAY);
			if (typeof display != "undefined") this.originalDisplay = display;
			return this;
		},

		findParent: function (simpleSelector, maxDepth, returnEl) {
			var p = this.dom, b = document.body, depth = 0, dq = Ext.DomQuery, stopEl;
			maxDepth = maxDepth || 50;
			if (typeof maxDepth != "number") {
				stopEl = Ext.getDom(maxDepth);
				maxDepth = 10;
			}
			while (p && p.nodeType == 1 && depth < maxDepth && p != b && p != stopEl) {
				if (dq.is(p, simpleSelector)) {
					return returnEl ? Ext.get(p) : p;
				}
				depth++;
				p = p.parentNode;
			}
			return null;
		},

		findParentNode: function (simpleSelector, maxDepth, returnEl) {
			var p = Ext.fly(this.dom.parentNode, '_internal');
			return p ? p.findParent(simpleSelector, maxDepth, returnEl) : null;
		},

		up: function (simpleSelector, maxDepth) {
			return this.findParentNode(simpleSelector, maxDepth, true);
		},

		is: function (simpleSelector) {
			return Ext.DomQuery.is(this.dom, simpleSelector);
		},

		animate: function (args, duration, onComplete, easing, animType) {
			this.anim(args, { duration: duration, callback: onComplete, easing: easing }, animType);
			return this;
		},

		anim: function (args, opt, animType, defaultDur, defaultEase, cb) {
			animType = animType || 'run';
			opt = opt || {};
			var anim = Ext.lib.Anim[animType](
            this.dom, args,
            (opt.duration || defaultDur) || .35,
            (opt.easing || defaultEase) || 'easeOut',
            function () {
            	Ext.callback(cb, this);
            	Ext.callback(opt.callback, opt.scope || this, [this, opt]);
            },
            this
        );
			opt.anim = anim;
			return anim;
		},

		preanim: function (a, i) {
			return !a[i] ? false : (typeof a[i] == "object" ? a[i] : { duration: a[i + 1], callback: a[i + 2], easing: a[i + 3] });
		},

		clean: function (forceReclean) {
			if (this.isCleaned && forceReclean !== true) {
				return this;
			}
			var ns = /\S/;
			var d = this.dom, n = d.firstChild, ni = -1;
			while (n) {
				var nx = n.nextSibling;
				if (n.nodeType == 3 && !ns.test(n.nodeValue)) {
					d.removeChild(n);
				} else {
					n.nodeIndex = ++ni;
				}
				n = nx;
			}
			this.isCleaned = true;
			return this;
		},

		scrollIntoView: function (container, hscroll) {
			var c = Ext.getDom(container) || Ext.getBody().dom;
			var el = this.dom;

			var o = this.getOffsetsTo(c),
            l = o[0] + c.scrollLeft,
            t = o[1] + c.scrollTop,
            b = t + el.offsetHeight,
            r = l + el.offsetWidth;

			var ch = c.clientHeight;
			var ct = parseInt(c.scrollTop, 10);
			var cl = parseInt(c.scrollLeft, 10);
			var cb = ct + ch;
			var cr = cl + c.clientWidth;

			if (el.offsetHeight > ch || t < ct) {
				c.scrollTop = t;
			} else if (b > cb) {
				c.scrollTop = b - ch;
			}
			c.scrollTop = c.scrollTop;
			if (hscroll !== false) {
				if (el.offsetWidth > c.clientWidth || l < cl) {
					c.scrollLeft = l;
				} else if (r > cr) {
					c.scrollLeft = r - c.clientWidth;
				}
				c.scrollLeft = c.scrollLeft;
			}
			return this;
		},

		scrollChildIntoView: function (child, hscroll) {
			Ext.fly(child, '_scrollChildIntoView').scrollIntoView(this, hscroll);
		},

		autoHeight: function (animate, duration, onComplete, easing) {
			var oldHeight = this.getHeight();
			this.clip();
			this.setHeight(1); setTimeout(function () {
				var height = parseInt(this.dom.scrollHeight, 10); if (!animate) {
					this.setHeight(height);
					this.unclip();
					if (typeof onComplete == "function") {
						onComplete();
					}
				} else {
					this.setHeight(oldHeight); this.setHeight(height, animate, duration, function () {
						this.unclip();
						if (typeof onComplete == "function") onComplete();
					} .createDelegate(this), easing);
				}
			} .createDelegate(this), 0);
			return this;
		},

		contains: function (el) {
			if (!el) { return false; }
			return D.isAncestor(this.dom, el.dom ? el.dom : el);
		},

		isVisible: function (deep) {
			var vis = !(this.getStyle("visibility") == "hidden" || this.getStyle("display") == "none");
			if (deep !== true || !vis) {
				return vis;
			}
			var p = this.dom;
			while (p && p.tagName.toLowerCase() != "body") {
				if (!Ext.fly(p, '_isVisible').isVisible()) {
					return false;
				}
				p = p.parentNode;
			}
			return true;
		},

		select: function (selector, unique) {
			return El.select(selector, unique, this.dom);
		},

		query: function (selector) {
			return Ext.DomQuery.select(selector, this.dom);
		},

		child: function (selector, returnDom) {
			var n = Ext.DomQuery.selectNode(selector, this.dom);
			return returnDom ? n : Ext.get(n);
		},

		down: function (selector, returnDom) {
			var n = Ext.DomQuery.selectNode(" > " + selector, this.dom);
			return returnDom ? n : Ext.get(n);
		},

		initDD: function (group, config, overrides) {
			var dd = new Ext.dd.DD(Ext.id(this.dom), group, config);
			return Ext.apply(dd, overrides);
		},

		initDDProxy: function (group, config, overrides) {
			var dd = new Ext.dd.DDProxy(Ext.id(this.dom), group, config);
			return Ext.apply(dd, overrides);
		},

		initDDTarget: function (group, config, overrides) {
			var dd = new Ext.dd.DDTarget(Ext.id(this.dom), group, config);
			return Ext.apply(dd, overrides);
		},

		setVisible: function (visible, animate) {
			if (!animate || !A) {
				if (this.visibilityMode == El.DISPLAY) {
					this.setDisplayed(visible);
				} else {
					this.fixDisplay();
					this.dom.style.visibility = visible ? "visible" : "hidden";
				}
			} else {
				var dom = this.dom;
				var visMode = this.visibilityMode;
				if (visible) {
					this.setOpacity(.01);
					this.setVisible(true);
				}
				this.anim({ opacity: { to: (visible ? 1 : 0)} },
                  this.preanim(arguments, 1),
                  null, .35, 'easeIn', function () {
                  	if (!visible) {
                  		if (visMode == El.DISPLAY) {
                  			dom.style.display = "none";
                  		} else {
                  			dom.style.visibility = "hidden";
                  		}
                  		Ext.get(dom).setOpacity(1);
                  	}
                  });
			}
			return this;
		},

		isDisplayed: function () {
			return this.getStyle("display") != "none";
		},

		toggle: function (animate) {
			this.setVisible(!this.isVisible(), this.preanim(arguments, 0));
			return this;
		},

		setDisplayed: function (value) {
			if (typeof value == "boolean") {
				value = value ? this.originalDisplay : "none";
			}
			this.setStyle("display", value);
			return this;
		},

		focus: function () {
			try {
				this.dom.focus();
			} catch (e) { }
			return this;
		},

		blur: function () {
			try {
				this.dom.blur();
			} catch (e) { }
			return this;
		},

		addClass: function (className) {
			if (Ext.isArray(className)) {
				for (var i = 0, len = className.length; i < len; i++) {
					this.addClass(className[i]);
				}
			} else {
				if (className && !this.hasClass(className)) {
					this.dom.className = this.dom.className + " " + className;
				}
			}
			return this;
		},

		radioClass: function (className) {
			var siblings = this.dom.parentNode.childNodes;
			for (var i = 0; i < siblings.length; i++) {
				var s = siblings[i];
				if (s.nodeType == 1) {
					Ext.get(s).removeClass(className);
				}
			}
			this.addClass(className);
			return this;
		},

		removeClass: function (className) {
			if (!className || !this.dom.className) {
				return this;
			}
			if (Ext.isArray(className)) {
				for (var i = 0, len = className.length; i < len; i++) {
					this.removeClass(className[i]);
				}
			} else {
				if (this.hasClass(className)) {
					var re = this.classReCache[className];
					if (!re) {
						re = new RegExp('(?:^|\\s+)' + className + '(?:\\s+|$)', "g");
						this.classReCache[className] = re;
					}
					this.dom.className =
                    this.dom.className.replace(re, " ");
				}
			}
			return this;
		},

		classReCache: {},

		toggleClass: function (className) {
			if (this.hasClass(className)) {
				this.removeClass(className);
			} else {
				this.addClass(className);
			}
			return this;
		},

		hasClass: function (className) {
			return className && (' ' + this.dom.className + ' ').indexOf(' ' + className + ' ') != -1;
		},

		replaceClass: function (oldClassName, newClassName) {
			this.removeClass(oldClassName);
			this.addClass(newClassName);
			return this;
		},

		getStyles: function () {
			var a = arguments, len = a.length, r = {};
			for (var i = 0; i < len; i++) {
				r[a[i]] = this.getStyle(a[i]);
			}
			return r;
		},

		getStyle: function () {
			return view && view.getComputedStyle ?
            function (prop) {
            	var el = this.dom, v, cs, camel;
            	if (prop == 'float') {
            		prop = "cssFloat";
            	}
            	if (v = el.style[prop]) {
            		return v;
            	}
            	if (cs = view.getComputedStyle(el, "")) {
            		if (!(camel = propCache[prop])) {
            			camel = propCache[prop] = prop.replace(camelRe, camelFn);
            		}
            		return cs[camel];
            	}
            	return null;
            } :
            function (prop) {
            	var el = this.dom, v, cs, camel;
            	if (prop == 'opacity') {
            		if (typeof el.style.filter == 'string') {
            			var m = el.style.filter.match(/alpha\(opacity=(.*)\)/i);
            			if (m) {
            				var fv = parseFloat(m[1]);
            				if (!isNaN(fv)) {
            					return fv ? fv / 100 : 0;
            				}
            			}
            		}
            		return 1;
            	} else if (prop == 'float') {
            		prop = "styleFloat";
            	}
            	if (!(camel = propCache[prop])) {
            		camel = propCache[prop] = prop.replace(camelRe, camelFn);
            	}
            	if (v = el.style[camel]) {
            		return v;
            	}
            	if (cs = el.currentStyle) {
            		return cs[camel];
            	}
            	return null;
            };
		} (),

		setStyle: function (prop, value) {
			if (typeof prop == "string") {
				var camel;
				if (!(camel = propCache[prop])) {
					camel = propCache[prop] = prop.replace(camelRe, camelFn);
				}
				if (camel == 'opacity') {
					this.setOpacity(value);
				} else {
					this.dom.style[camel] = value;
				}
			} else {
				for (var style in prop) {
					if (typeof prop[style] != "function") {
						this.setStyle(style, prop[style]);
					}
				}
			}
			return this;
		},

		applyStyles: function (style) {
			Ext.DomHelper.applyStyles(this.dom, style);
			return this;
		},

		getX: function () {
			return D.getX(this.dom);
		},

		getY: function () {
			return D.getY(this.dom);
		},

		getXY: function () {
			return D.getXY(this.dom);
		},

		getOffsetsTo: function (el) {
			var o = this.getXY();
			var e = Ext.fly(el, '_internal').getXY();
			return [o[0] - e[0], o[1] - e[1]];
		},

		setX: function (x, animate) {
			if (!animate || !A) {
				D.setX(this.dom, x);
			} else {
				this.setXY([x, this.getY()], this.preanim(arguments, 1));
			}
			return this;
		},

		setY: function (y, animate) {
			if (!animate || !A) {
				D.setY(this.dom, y);
			} else {
				this.setXY([this.getX(), y], this.preanim(arguments, 1));
			}
			return this;
		},

		setLeft: function (left) {
			this.setStyle("left", this.addUnits(left));
			return this;
		},

		setTop: function (top) {
			this.setStyle("top", this.addUnits(top));
			return this;
		},

		setRight: function (right) {
			this.setStyle("right", this.addUnits(right));
			return this;
		},

		setBottom: function (bottom) {
			this.setStyle("bottom", this.addUnits(bottom));
			return this;
		},

		setXY: function (pos, animate) {
			if (!animate || !A) {
				D.setXY(this.dom, pos);
			} else {
				this.anim({ points: { to: pos} }, this.preanim(arguments, 1), 'motion');
			}
			return this;
		},

		setLocation: function (x, y, animate) {
			this.setXY([x, y], this.preanim(arguments, 2));
			return this;
		},

		moveTo: function (x, y, animate) {
			this.setXY([x, y], this.preanim(arguments, 2));
			return this;
		},

		getRegion: function () {
			return D.getRegion(this.dom);
		},

		getHeight: function (contentHeight) {
			var h = this.dom.offsetHeight || 0;
			h = contentHeight !== true ? h : h - this.getBorderWidth("tb") - this.getPadding("tb");
			return h < 0 ? 0 : h;
		},

		getWidth: function (contentWidth) {
			var w = this.dom.offsetWidth || 0;
			w = contentWidth !== true ? w : w - this.getBorderWidth("lr") - this.getPadding("lr");
			return w < 0 ? 0 : w;
		},

		getComputedHeight: function () {
			var h = Math.max(this.dom.offsetHeight, this.dom.clientHeight);
			if (!h) {
				h = parseInt(this.getStyle('height'), 10) || 0;
				if (!this.isBorderBox()) {
					h += this.getFrameWidth('tb');
				}
			}
			return h;
		},

		getComputedWidth: function () {
			var w = Math.max(this.dom.offsetWidth, this.dom.clientWidth);
			if (!w) {
				w = parseInt(this.getStyle('width'), 10) || 0;
				if (!this.isBorderBox()) {
					w += this.getFrameWidth('lr');
				}
			}
			return w;
		},

		getSize: function (contentSize) {
			return { width: this.getWidth(contentSize), height: this.getHeight(contentSize) };
		},

		getStyleSize: function () {
			var w, h, d = this.dom, s = d.style;
			if (s.width && s.width != 'auto') {
				w = parseInt(s.width, 10);
				if (Ext.isBorderBox) {
					w -= this.getFrameWidth('lr');
				}
			}
			if (s.height && s.height != 'auto') {
				h = parseInt(s.height, 10);
				if (Ext.isBorderBox) {
					h -= this.getFrameWidth('tb');
				}
			}
			return { width: w || this.getWidth(true), height: h || this.getHeight(true) };

		},

		getViewSize: function () {
			var d = this.dom, doc = document, aw = 0, ah = 0;
			if (d == doc || d == doc.body) {
				return { width: D.getViewWidth(), height: D.getViewHeight() };
			} else {
				return {
					width: d.clientWidth,
					height: d.clientHeight
				};
			}
		},

		getValue: function (asNumber) {
			return asNumber ? parseInt(this.dom.value, 10) : this.dom.value;
		},

		adjustWidth: function (width) {
			if (typeof width == "number") {
				if (this.autoBoxAdjust && !this.isBorderBox()) {
					width -= (this.getBorderWidth("lr") + this.getPadding("lr"));
				}
				if (width < 0) {
					width = 0;
				}
			}
			return width;
		},

		adjustHeight: function (height) {
			if (typeof height == "number") {
				if (this.autoBoxAdjust && !this.isBorderBox()) {
					height -= (this.getBorderWidth("tb") + this.getPadding("tb"));
				}
				if (height < 0) {
					height = 0;
				}
			}
			return height;
		},

		setWidth: function (width, animate) {
			width = this.adjustWidth(width);
			if (!animate || !A) {
				this.dom.style.width = this.addUnits(width);
			} else {
				this.anim({ width: { to: width} }, this.preanim(arguments, 1));
			}
			return this;
		},

		setHeight: function (height, animate) {
			height = this.adjustHeight(height);
			if (!animate || !A) {
				this.dom.style.height = this.addUnits(height);
			} else {
				this.anim({ height: { to: height} }, this.preanim(arguments, 1));
			}
			return this;
		},

		setSize: function (width, height, animate) {
			if (typeof width == "object") {
				height = width.height; width = width.width;
			}
			width = this.adjustWidth(width); height = this.adjustHeight(height);
			if (!animate || !A) {
				this.dom.style.width = this.addUnits(width);
				this.dom.style.height = this.addUnits(height);
			} else {
				this.anim({ width: { to: width }, height: { to: height} }, this.preanim(arguments, 2));
			}
			return this;
		},

		setBounds: function (x, y, width, height, animate) {
			if (!animate || !A) {
				this.setSize(width, height);
				this.setLocation(x, y);
			} else {
				width = this.adjustWidth(width); height = this.adjustHeight(height);
				this.anim({ points: { to: [x, y] }, width: { to: width }, height: { to: height} },
                          this.preanim(arguments, 4), 'motion');
			}
			return this;
		},

		setRegion: function (region, animate) {
			this.setBounds(region.left, region.top, region.right - region.left, region.bottom - region.top, this.preanim(arguments, 1));
			return this;
		},

		addListener: function (eventName, fn, scope, options) {
			Ext.EventManager.on(this.dom, eventName, fn, scope || this, options);
		},

		removeListener: function (eventName, fn, scope) {
			Ext.EventManager.removeListener(this.dom, eventName, fn, scope || this);
			return this;
		},

		removeAllListeners: function () {
			Ext.EventManager.removeAll(this.dom);
			return this;
		},

		relayEvent: function (eventName, observable) {
			this.on(eventName, function (e) {
				observable.fireEvent(eventName, e);
			});
		},

		setOpacity: function (opacity, animate) {
			if (!animate || !A) {
				var s = this.dom.style;
				if (Ext.isIE) {
					s.zoom = 1;
					s.filter = (s.filter || '').replace(/alpha\([^\)]*\)/gi, "") +
                           (opacity == 1 ? "" : " alpha(opacity=" + opacity * 100 + ")");
				} else {
					s.opacity = opacity;
				}
			} else {
				this.anim({ opacity: { to: opacity} }, this.preanim(arguments, 1), null, .35, 'easeIn');
			}
			return this;
		},

		getLeft: function (local) {
			if (!local) {
				return this.getX();
			} else {
				return parseInt(this.getStyle("left"), 10) || 0;
			}
		},

		getRight: function (local) {
			if (!local) {
				return this.getX() + this.getWidth();
			} else {
				return (this.getLeft(true) + this.getWidth()) || 0;
			}
		},

		getTop: function (local) {
			if (!local) {
				return this.getY();
			} else {
				return parseInt(this.getStyle("top"), 10) || 0;
			}
		},

		getBottom: function (local) {
			if (!local) {
				return this.getY() + this.getHeight();
			} else {
				return (this.getTop(true) + this.getHeight()) || 0;
			}
		},

		position: function (pos, zIndex, x, y) {
			if (!pos) {
				if (this.getStyle('position') == 'static') {
					this.setStyle('position', 'relative');
				}
			} else {
				this.setStyle("position", pos);
			}
			if (zIndex) {
				this.setStyle("z-index", zIndex);
			}
			if (x !== undefined && y !== undefined) {
				this.setXY([x, y]);
			} else if (x !== undefined) {
				this.setX(x);
			} else if (y !== undefined) {
				this.setY(y);
			}
		},

		clearPositioning: function (value) {
			value = value || '';
			this.setStyle({
				"left": value,
				"right": value,
				"top": value,
				"bottom": value,
				"z-index": "",
				"position": "static"
			});
			return this;
		},

		getPositioning: function () {
			var l = this.getStyle("left");
			var t = this.getStyle("top");
			return {
				"position": this.getStyle("position"),
				"left": l,
				"right": l ? "" : this.getStyle("right"),
				"top": t,
				"bottom": t ? "" : this.getStyle("bottom"),
				"z-index": this.getStyle("z-index")
			};
		},

		getBorderWidth: function (side) {
			return this.addStyles(side, El.borders);
		},

		getPadding: function (side) {
			return this.addStyles(side, El.paddings);
		},

		setPositioning: function (pc) {
			this.applyStyles(pc);
			if (pc.right == "auto") {
				this.dom.style.right = "";
			}
			if (pc.bottom == "auto") {
				this.dom.style.bottom = "";
			}
			return this;
		},

		fixDisplay: function () {
			if (this.getStyle("display") == "none") {
				this.setStyle("visibility", "hidden");
				this.setStyle("display", this.originalDisplay); if (this.getStyle("display") == "none") {
					this.setStyle("display", "block");
				}
			}
		},

		setOverflow: function (v) {
			if (v == 'auto' && Ext.isMac && Ext.isGecko2) {
				this.dom.style.overflow = 'hidden';
				(function () { this.dom.style.overflow = 'auto'; }).defer(1, this);
			} else {
				this.dom.style.overflow = v;
			}
		},

		setLeftTop: function (left, top) {
			this.dom.style.left = this.addUnits(left);
			this.dom.style.top = this.addUnits(top);
			return this;
		},

		move: function (direction, distance, animate) {
			var xy = this.getXY();
			direction = direction.toLowerCase();
			switch (direction) {
				case "l":
				case "left":
					this.moveTo(xy[0] - distance, xy[1], this.preanim(arguments, 2));
					break;
				case "r":
				case "right":
					this.moveTo(xy[0] + distance, xy[1], this.preanim(arguments, 2));
					break;
				case "t":
				case "top":
				case "up":
					this.moveTo(xy[0], xy[1] - distance, this.preanim(arguments, 2));
					break;
				case "b":
				case "bottom":
				case "down":
					this.moveTo(xy[0], xy[1] + distance, this.preanim(arguments, 2));
					break;
			}
			return this;
		},

		clip: function () {
			if (!this.isClipped) {
				this.isClipped = true;
				this.originalClip = {
					"o": this.getStyle("overflow"),
					"x": this.getStyle("overflow-x"),
					"y": this.getStyle("overflow-y")
				};
				this.setStyle("overflow", "hidden");
				this.setStyle("overflow-x", "hidden");
				this.setStyle("overflow-y", "hidden");
			}
			return this;
		},

		unclip: function () {
			if (this.isClipped) {
				this.isClipped = false;
				var o = this.originalClip;
				if (o.o) { this.setStyle("overflow", o.o); }
				if (o.x) { this.setStyle("overflow-x", o.x); }
				if (o.y) { this.setStyle("overflow-y", o.y); }
			}
			return this;
		},

		getAnchorXY: function (anchor, local, s) {
			var w, h, vp = false;
			if (!s) {
				var d = this.dom;
				if (d == document.body || d == document) {
					vp = true;
					w = D.getViewWidth(); h = D.getViewHeight();
				} else {
					w = this.getWidth(); h = this.getHeight();
				}
			} else {
				w = s.width; h = s.height;
			}
			var x = 0, y = 0, r = Math.round;
			switch ((anchor || "tl").toLowerCase()) {
				case "c":
					x = r(w * .5);
					y = r(h * .5);
					break;
				case "t":
					x = r(w * .5);
					y = 0;
					break;
				case "l":
					x = 0;
					y = r(h * .5);
					break;
				case "r":
					x = w;
					y = r(h * .5);
					break;
				case "b":
					x = r(w * .5);
					y = h;
					break;
				case "tl":
					x = 0;
					y = 0;
					break;
				case "bl":
					x = 0;
					y = h;
					break;
				case "br":
					x = w;
					y = h;
					break;
				case "tr":
					x = w;
					y = 0;
					break;
			}
			if (local === true) {
				return [x, y];
			}
			if (vp) {
				var sc = this.getScroll();
				return [x + sc.left, y + sc.top];
			}
			var o = this.getXY();
			return [x + o[0], y + o[1]];
		},

		getAlignToXY: function (el, p, o) {
			el = Ext.get(el);
			if (!el || !el.dom) {
				throw "Element.alignToXY с несуществующим элементом";
			}
			var d = this.dom;
			var c = false; var p1 = "", p2 = "";
			o = o || [0, 0];

			if (!p) {
				p = "tl-bl";
			} else if (p == "?") {
				p = "tl-bl?";
			} else if (p.indexOf("-") == -1) {
				p = "tl-" + p;
			}
			p = p.toLowerCase();
			var m = p.match(/^([a-z]+)-([a-z]+)(\?)?$/);
			if (!m) {
				throw "Element.alignTo с недопустимым выравниванием " + p;
			}
			p1 = m[1]; p2 = m[2]; c = !!m[3];

			var a1 = this.getAnchorXY(p1, true);
			var a2 = el.getAnchorXY(p2, false);

			var x = a2[0] - a1[0] + o[0];
			var y = a2[1] - a1[1] + o[1];

			if (c) {
				var w = this.getWidth(), h = this.getHeight(), r = el.getRegion();
				var dw = D.getViewWidth() - 5, dh = D.getViewHeight() - 5;

				var p1y = p1.charAt(0), p1x = p1.charAt(p1.length - 1);
				var p2y = p2.charAt(0), p2x = p2.charAt(p2.length - 1);
				var swapY = ((p1y == "t" && p2y == "b") || (p1y == "b" && p2y == "t"));
				var swapX = ((p1x == "r" && p2x == "l") || (p1x == "l" && p2x == "r"));

				var doc = document;
				var scrollX = (doc.documentElement.scrollLeft || doc.body.scrollLeft || 0) + 5;
				var scrollY = (doc.documentElement.scrollTop || doc.body.scrollTop || 0) + 5;

				if ((x + w) > dw + scrollX) {
					x = swapX ? r.left - w : dw + scrollX - w;
				}
				if (x < scrollX) {
					x = swapX ? r.right : scrollX;
				}
				if ((y + h) > dh + scrollY) {
					y = swapY ? r.top - h : dh + scrollY - h;
				}
				if (y < scrollY) {
					y = swapY ? r.bottom : scrollY;
				}
			}
			return [x, y];
		},

		getConstrainToXY: function () {
			var os = { top: 0, left: 0, bottom: 0, right: 0 };

			return function (el, local, offsets, proposedXY) {
				el = Ext.get(el);
				offsets = offsets ? Ext.applyIf(offsets, os) : os;

				var vw, vh, vx = 0, vy = 0;
				if (el.dom == document.body || el.dom == document) {
					vw = Ext.lib.Dom.getViewWidth();
					vh = Ext.lib.Dom.getViewHeight();
				} else {
					vw = el.dom.clientWidth;
					vh = el.dom.clientHeight;
					if (!local) {
						var vxy = el.getXY();
						vx = vxy[0];
						vy = vxy[1];
					}
				}

				var s = el.getScroll();

				vx += offsets.left + s.left;
				vy += offsets.top + s.top;

				vw -= offsets.right;
				vh -= offsets.bottom;

				var vr = vx + vw;
				var vb = vy + vh;

				var xy = proposedXY || (!local ? this.getXY() : [this.getLeft(true), this.getTop(true)]);
				var x = xy[0], y = xy[1];
				var w = this.dom.offsetWidth, h = this.dom.offsetHeight;

				var moved = false;

				if ((x + w) > vr) {
					x = vr - w;
					moved = true;
				}
				if ((y + h) > vb) {
					y = vb - h;
					moved = true;
				}
				if (x < vx) {
					x = vx;
					moved = true;
				}
				if (y < vy) {
					y = vy;
					moved = true;
				}
				return moved ? [x, y] : false;
			};
		} (),

		adjustForConstraints: function (xy, parent, offsets) {
			return this.getConstrainToXY(parent || document, false, offsets, xy) || xy;
		},

		alignTo: function (element, position, offsets, animate) {
			var xy = this.getAlignToXY(element, position, offsets);
			this.setXY(xy, this.preanim(arguments, 3));
			return this;
		},

		anchorTo: function (el, alignment, offsets, animate, monitorScroll, callback) {
			var action = function () {
				this.alignTo(el, alignment, offsets, animate);
				Ext.callback(callback, this);
			};
			Ext.EventManager.onWindowResize(action, this);
			var tm = typeof monitorScroll;
			if (tm != 'undefined') {
				Ext.EventManager.on(window, 'scroll', action, this,
                { buffer: tm == 'number' ? monitorScroll : 50 });
			}
			action.call(this); return this;
		},

		clearOpacity: function () {
			if (window.ActiveXObject) {
				if (typeof this.dom.style.filter == 'string' && (/alpha/i).test(this.dom.style.filter)) {
					this.dom.style.filter = "";
				}
			} else {
				this.dom.style.opacity = "";
				this.dom.style["-moz-opacity"] = "";
				this.dom.style["-khtml-opacity"] = "";
			}
			return this;
		},

		hide: function (animate) {
			this.setVisible(false, this.preanim(arguments, 0));
			return this;
		},

		show: function (animate) {
			this.setVisible(true, this.preanim(arguments, 0));
			return this;
		},

		addUnits: function (size) {
			return Ext.Element.addUnits(size, this.defaultUnit);
		},

		update: function (html, loadScripts, callback) {
			if (typeof html == "undefined") {
				html = "";
			}
			if (loadScripts !== true) {
				this.dom.innerHTML = html;
				if (typeof callback == "function") {
					callback();
				}
				return this;
			}
			var id = Ext.id();
			var dom = this.dom;

			html += '<span id="' + id + '"></span>';

			E.onAvailable(id, function () {
				var hd = document.getElementsByTagName("head")[0];
				var re = /(?:<script([^>]*)?>)((\n|\r|.)*?)(?:<\/script>)/ig;
				var srcRe = /\ssrc=([\'\"])(.*?)\1/i;
				var typeRe = /\stype=([\'\"])(.*?)\1/i;

				var match;
				while (match = re.exec(html)) {
					var attrs = match[1];
					var srcMatch = attrs ? attrs.match(srcRe) : false;
					if (srcMatch && srcMatch[2]) {
						var s = document.createElement("script");
						s.src = srcMatch[2];
						var typeMatch = attrs.match(typeRe);
						if (typeMatch && typeMatch[2]) {
							s.type = typeMatch[2];
						}
						hd.appendChild(s);
					} else if (match[2] && match[2].length > 0) {
						if (window.execScript) {
							window.execScript(match[2]);
						} else {
							window.eval(match[2]);
						}
					}
				}
				var el = document.getElementById(id);
				if (el) { Ext.removeNode(el); }
				if (typeof callback == "function") {
					callback();
				}
			});
			dom.innerHTML = html.replace(/(?:<script.*?>)((\n|\r|.)*?)(?:<\/script>)/ig, "");
			return this;
		},

		load: function () {
			var um = this.getUpdater();
			um.update.apply(um, arguments);
			return this;
		},

		getUpdater: function () {
			if (!this.updateManager) {
				this.updateManager = new Ext.Updater(this);
			}
			return this.updateManager;
		},

		unselectable: function () {
			if (this.dom.nodeType == 3) {
				return;
			}
			this.dom.unselectable = "on";
			this.swallowEvent("selectstart", true);
			this.applyStyles("-moz-user-select:none;-khtml-user-select:none;");
			this.addClass("x-unselectable");
			var childNodes = this.dom.childNodes;
			for (var i = 0; i < childNodes.length; i++) {
				var node = childNodes[i];
				Ext.fly(node).unselectable();
			}
			return this;
		},

		getCenterXY: function () {
			return this.getAlignToXY(document, 'c-c');
		},

		center: function (centerIn) {
			this.alignTo(centerIn || document, 'c-c');
			return this;
		},

		isBorderBox: function () {
			return noBoxAdjust[this.dom.tagName.toLowerCase()] || Ext.isBorderBox;
		},

		getBox: function (contentBox, local) {
			var xy;
			if (!local) {
				xy = this.getXY();
			} else {
				var left = parseInt(this.getStyle("left"), 10) || 0;
				var top = parseInt(this.getStyle("top"), 10) || 0;
				xy = [left, top];
			}
			var el = this.dom, w = el.offsetWidth, h = el.offsetHeight, bx;
			if (!contentBox) {
				bx = { x: xy[0], y: xy[1], 0: xy[0], 1: xy[1], width: w, height: h };
			} else {
				var l = this.getBorderWidth("l") + this.getPadding("l");
				var r = this.getBorderWidth("r") + this.getPadding("r");
				var t = this.getBorderWidth("t") + this.getPadding("t");
				var b = this.getBorderWidth("b") + this.getPadding("b");
				bx = { x: xy[0] + l, y: xy[1] + t, 0: xy[0] + l, 1: xy[1] + t, width: w - (l + r), height: h - (t + b) };
			}
			bx.right = bx.x + bx.width;
			bx.bottom = bx.y + bx.height;
			return bx;
		},

		getFrameWidth: function (sides, onlyContentBox) {
			return onlyContentBox && Ext.isBorderBox ? 0 : (this.getPadding(sides) + this.getBorderWidth(sides));
		},

		setBox: function (box, adjust, animate) {
			var w = box.width, h = box.height;
			if ((adjust && !this.autoBoxAdjust) && !this.isBorderBox()) {
				w -= (this.getBorderWidth("lr") + this.getPadding("lr"));
				h -= (this.getBorderWidth("tb") + this.getPadding("tb"));
			}
			this.setBounds(box.x, box.y, w, h, this.preanim(arguments, 2));
			return this;
		},

		repaint: function () {
			var dom = this.dom;
			this.addClass("x-repaint");
			setTimeout(function () {
				Ext.get(dom).removeClass("x-repaint");
			}, 1);
			return this;
		},

		getMargins: function (side) {
			if (!side) {
				return {
					top: parseInt(this.getStyle("margin-top"), 10) || 0,
					left: parseInt(this.getStyle("margin-left"), 10) || 0,
					bottom: parseInt(this.getStyle("margin-bottom"), 10) || 0,
					right: parseInt(this.getStyle("margin-right"), 10) || 0
				};
			} else {
				return this.addStyles(side, El.margins);
			}
		},

		addStyles: function (sides, styles) {
			var val = 0, v, w;
			for (var i = 0, len = sides.length; i < len; i++) {
				v = this.getStyle(styles[sides.charAt(i)]);
				if (v) {
					w = parseInt(v, 10);
					if (w) { val += (w >= 0 ? w : -1 * w); }
				}
			}
			return val;
		},

		createProxy: function (config, renderTo, matchBox) {
			config = typeof config == "object" ?
            config : { tag: "div", cls: config };

			var proxy;
			if (renderTo) {
				proxy = Ext.DomHelper.append(renderTo, config, true);
			} else {
				proxy = Ext.DomHelper.insertBefore(this.dom, config, true);
			}
			if (matchBox) {
				proxy.setBox(this.getBox());
			}
			return proxy;
		},

		mask: function (msg, msgCls, isDynamicPosition, fitToElement, isTransparent, opacity, isTopElement) {
			if (this.getStyle("position") == "static") {
				this.setStyle("position", "relative");
			}
			if (this._maskMsg) {
				this._maskMsg.remove();
			}
			if (this._mask) {
				this._mask.remove();
			}
			this._mask = Ext.DomHelper.append(this.dom, { cls: "ext-el-mask" }, true);
			this.addClass("x-masked");
			var mask = this._mask;
			if (isTransparent) {
				mask.setStyle('background-color', opacity ? 'ffffff' : '#f0f0f0');
				mask.setStyle('opacity', opacity || '0.6');
			}
			if (isTopElement !== true) {
				mask.setStyle('z-index', '5000');
			}
			this._mask.setDisplayed(true);
			var className = "ext-el-mask-msg";
			if (fitToElement) {
				className += " fit";
			}
			if (msgCls) {
				className += " " + msgCls;
			}
			if (typeof msg == 'string') {
				this._maskMsg = Ext.DomHelper.append(this.dom, { cls: className, cn: { tag: 'div', cls: 'center'} }, true);
				var mm = this._maskMsg;
				mm.dom.className = className;
				var messageContainer = mm.dom.firstChild;
				if (Terrasoft && Terrasoft.isDebug) {
					var start = Math.floor(new Date().getTime() / 1000);
					var getTimerMsg = function (startTime) {
						var seconds = Math.floor(new Date().getTime() / 1000) - startTime;
						return seconds + " s";
					};
					this._maskTimer = setInterval(
						function () {
							var msgUpd = msg + ": " + getTimerMsg(start);
							messageContainer.innerHTML = msgUpd;
						}, 1000);
				}
				messageContainer.innerHTML = msg;
				mm.setDisplayed(true);
				if (!fitToElement) {
					Ext.DomHelper.insertBefore(messageContainer, { cls: 'left-side' }, true);
					Ext.DomHelper.insertAfter(messageContainer, { cls: 'right-side' }, true);
				}
				var middleEl = mm;
				if (fitToElement) {
					middleEl = Ext.get(messageContainer);
				}
				if (isDynamicPosition) {
					middleEl.dom.style.marginTop = mm.addUnits(-middleEl.dom.offsetHeight / 2);
					middleEl.dom.style.marginLeft = mm.addUnits(-middleEl.dom.offsetWidth / 2);
				} else {
					mm.center(this);
				}
			}
			if (Ext.isIE && !(Ext.isIE7 && Ext.isStrict) && this.getStyle('height') == 'auto') {
				this._mask.setSize(this.dom.clientWidth, this.getHeight());
			}
			this._mask.on('contextmenu', function (e) {
				e.stopEvent();
			}, this);
			return this._mask;
		},

		unmask: function () {
			if (this._mask) {
				if (this._maskTimer) {
					clearInterval(this._maskTimer);
				}
				if (this._maskMsg) {
					this._maskMsg.remove();
					delete this._maskMsg;
				}
				this._mask.remove();
				delete this._mask;
			}
			this.removeClass("x-masked");
		},

		isMasked: function () {
			return this._mask && this._mask.isVisible();
		},

		createShim: function () {
			var el = document.createElement('iframe');
			el.frameBorder = '0';
			el.className = 'ext-shim';
			if (Ext.isIE && Ext.isSecure) {
				el.src = Ext.SSL_SECURE_URL;
			}
			var shim = Ext.get(this.dom.parentNode.insertBefore(el, this.dom));
			shim.autoBoxAdjust = false;
			return shim;
		},

		remove: function () {
			Ext.removeNode(this.dom);
			delete El.cache[this.dom.id];
		},

		hover: function (overFn, outFn, scope) {
			var preOverFn = function (e) {
				if (!e.within(this, true)) {
					overFn.apply(scope || this, arguments);
				}
			};
			var preOutFn = function (e) {
				if (!e.within(this, true)) {
					outFn.apply(scope || this, arguments);
				}
			};
			this.on("mouseover", preOverFn, this.dom);
			this.on("mouseout", preOutFn, this.dom);
			return this;
		},

		addClassOnOver: function (className) {
			this.hover(
            function () {
            	Ext.fly(this, '_internal').addClass(className);
            },
            function () {
            	Ext.fly(this, '_internal').removeClass(className);
            }
        );
			return this;
		},

		addClassOnFocus: function (className) {
			this.on("focus", function () {
				Ext.fly(this, '_internal').addClass(className);
			}, this.dom);
			this.on("blur", function () {
				Ext.fly(this, '_internal').removeClass(className);
			}, this.dom);
			return this;
		},

		addClassOnClick: function (className) {
			var dom = this.dom;
			this.on("mousedown", function () {
				Ext.fly(dom, '_internal').addClass(className);
				var d = Ext.getDoc();
				var fn = function () {
					Ext.fly(dom, '_internal').removeClass(className);
					d.removeListener("mouseup", fn);
				};
				d.on("mouseup", fn);
			});
			return this;
		},

		swallowEvent: function (eventName, preventDefault) {
			var fn = function (e) {
				e.stopPropagation();
				if (preventDefault) {
					e.preventDefault();
				}
			};
			if (Ext.isArray(eventName)) {
				for (var i = 0, len = eventName.length; i < len; i++) {
					this.on(eventName[i], fn);
				}
				return this;
			}
			this.on(eventName, fn);
			return this;
		},

		parent: function (selector, returnDom) {
			return this.matchNode('parentNode', 'parentNode', selector, returnDom);
		},

		next: function (selector, returnDom) {
			return this.matchNode('nextSibling', 'nextSibling', selector, returnDom);
		},

		prev: function (selector, returnDom) {
			return this.matchNode('previousSibling', 'previousSibling', selector, returnDom);
		},

		first: function (selector, returnDom) {
			return this.matchNode('nextSibling', 'firstChild', selector, returnDom);
		},

		last: function (selector, returnDom) {
			return this.matchNode('previousSibling', 'lastChild', selector, returnDom);
		},

		matchNode: function (dir, start, selector, returnDom) {
			var n = this.dom[start];
			while (n) {
				if (n.nodeType == 1 && (!selector || Ext.DomQuery.is(n, selector))) {
					return !returnDom ? Ext.get(n) : n;
				}
				n = n[dir];
			}
			return null;
		},

		appendChild: function (el) {
			el = Ext.get(el);
			el.appendTo(this);
			return this;
		},

		createChild: function (config, insertBefore, returnDom) {
			config = config || { tag: 'div' };
			if (insertBefore) {
				return Ext.DomHelper.insertBefore(insertBefore, config, returnDom !== true);
			}
			return Ext.DomHelper[!this.dom.firstChild ? 'overwrite' : 'append'](this.dom, config, returnDom !== true);
		},

		appendTo: function (el) {
			el = Ext.getDom(el);
			el.appendChild(this.dom);
			return this;
		},

		insertBefore: function (el) {
			el = Ext.getDom(el);
			el.parentNode.insertBefore(this.dom, el);
			return this;
		},

		insertAfter: function (el) {
			el = Ext.getDom(el);
			el.parentNode.insertBefore(this.dom, el.nextSibling);
			return this;
		},

		insertFirst: function (el, returnDom) {
			el = el || {};
			if (typeof el == 'object' && !el.nodeType && !el.dom) {
				return this.createChild(el, this.dom.firstChild, returnDom);
			} else {
				el = Ext.getDom(el);
				this.dom.insertBefore(el, this.dom.firstChild);
				return !returnDom ? Ext.get(el) : el;
			}
		},

		insertSibling: function (el, where, returnDom) {
			var rt;
			if (Ext.isArray(el)) {
				for (var i = 0, len = el.length; i < len; i++) {
					rt = this.insertSibling(el[i], where, returnDom);
				}
				return rt;
			}
			where = where ? where.toLowerCase() : 'before';
			el = el || {};
			var refNode = where == 'before' ? this.dom : this.dom.nextSibling;

			if (typeof el == 'object' && !el.nodeType && !el.dom) {
				if (where == 'after' && !this.dom.nextSibling) {
					rt = Ext.DomHelper.append(this.dom.parentNode, el, !returnDom);
				} else {
					rt = Ext.DomHelper[where == 'after' ? 'insertAfter' : 'insertBefore'](this.dom, el, !returnDom);
				}

			} else {
				rt = this.dom.parentNode.insertBefore(Ext.getDom(el), refNode);
				if (!returnDom) {
					rt = Ext.get(rt);
				}
			}
			return rt;
		},

		wrap: function (config, returnDom) {
			if (!config) {
				config = { tag: "div" };
			}
			var newEl = Ext.DomHelper.insertBefore(this.dom, config, !returnDom);
			newEl.dom ? newEl.dom.appendChild(this.dom) : newEl.appendChild(this.dom);
			return newEl;
		},

		replace: function (el) {
			el = Ext.get(el);
			this.insertBefore(el);
			el.remove();
			return this;
		},

		replaceWith: function (el) {
			if (typeof el == 'object' && !el.nodeType && !el.dom) {
				el = this.insertSibling(el, 'before');
			} else {
				el = Ext.getDom(el);
				this.dom.parentNode.insertBefore(el, this.dom);
			}
			El.uncache(this.id);
			this.dom.parentNode.removeChild(this.dom);
			this.dom = el;
			this.id = Ext.id(el);
			El.cache[this.id] = this;
			return this;
		},

		insertHtml: function (where, html, returnEl) {
			var el = Ext.DomHelper.insertHtml(where, this.dom, html);
			return returnEl ? Ext.get(el) : el;
		},

		set: function (o, useSet) {
			var el = this.dom;
			useSet = typeof useSet == 'undefined' ? (el.setAttribute ? true : false) : useSet;
			for (var attr in o) {
				if (attr == "style" || typeof o[attr] == "function") continue;
				if (attr == "cls") {
					el.className = o["cls"];
				} else if (o.hasOwnProperty(attr)) {
					if (useSet) el.setAttribute(attr, o[attr]);
					else el[attr] = o[attr];
				}
			}
			if (o.style) {
				Ext.DomHelper.applyStyles(el, o.style);
			}
			return this;
		},

		addKeyListener: function (key, fn, scope) {
			var config;
			if (typeof key != "object" || Ext.isArray(key)) {
				config = {
					key: key,
					fn: fn,
					scope: scope
				};
			} else {
				config = {
					key: key.key,
					shift: key.shift,
					ctrl: key.ctrl,
					alt: key.alt,
					fn: fn,
					scope: scope
				};
			}
			return new Ext.KeyMap(this, config);
		},

		addKeyMap: function (config) {
			return new Ext.KeyMap(this, config);
		},

		isScrollable: function () {
			var dom = this.dom;
			return dom.scrollHeight > dom.clientHeight || dom.scrollWidth > dom.clientWidth;
		},

		scrollTo: function (side, value, animate) {
			var prop = side.toLowerCase() == "left" ? "scrollLeft" : "scrollTop";
			if (!animate || !A) {
				this.dom[prop] = value;
			} else {
				var to = prop == "scrollLeft" ? [value, this.dom.scrollTop] : [this.dom.scrollLeft, value];
				this.anim({ scroll: { "to": to} }, this.preanim(arguments, 2), 'scroll');
			}
			return this;
		},

		scroll: function (direction, distance, animate) {
			if (!this.isScrollable()) {
				return;
			}
			var el = this.dom;
			var l = el.scrollLeft, t = el.scrollTop;
			var w = el.scrollWidth, h = el.scrollHeight;
			var cw = el.clientWidth, ch = el.clientHeight;
			direction = direction.toLowerCase();
			var scrolled = false;
			var a = this.preanim(arguments, 2);
			switch (direction) {
				case "l":
				case "left":
					if (w - l > cw) {
						var v = Math.min(l + distance, w - cw);
						this.scrollTo("left", v, a);
						scrolled = true;
					}
					break;
				case "r":
				case "right":
					if (l > 0) {
						var v = Math.max(l - distance, 0);
						this.scrollTo("left", v, a);
						scrolled = true;
					}
					break;
				case "t":
				case "top":
				case "up":
					if (t > 0) {
						var v = Math.max(t - distance, 0);
						this.scrollTo("top", v, a);
						scrolled = true;
					}
					break;
				case "b":
				case "bottom":
				case "down":
					if (h - t > ch) {
						var v = Math.min(t + distance, h - ch);
						this.scrollTo("top", v, a);
						scrolled = true;
					}
					break;
			}
			return scrolled;
		},

		translatePoints: function (x, y) {
			if (typeof x == 'object' || Ext.isArray(x)) {
				y = x[1]; x = x[0];
			}
			var p = this.getStyle('position');
			var o = this.getXY();

			var l = parseInt(this.getStyle('left'), 10);
			var t = parseInt(this.getStyle('top'), 10);

			if (isNaN(l)) {
				l = (p == "relative") ? 0 : this.dom.offsetLeft;
			}
			if (isNaN(t)) {
				t = (p == "relative") ? 0 : this.dom.offsetTop;
			}

			return { left: (x - o[0] + l), top: (y - o[1] + t) };
		},

		getScroll: function () {
			var d = this.dom, doc = document;
			if (d == doc || d == doc.body) {
				var l, t;
				if (Ext.isIE && Ext.isStrict) {
					l = doc.documentElement.scrollLeft || (doc.body.scrollLeft || 0);
					t = doc.documentElement.scrollTop || (doc.body.scrollTop || 0);
				} else {
					l = window.pageXOffset || (doc.body.scrollLeft || 0);
					t = window.pageYOffset || (doc.body.scrollTop || 0);
				}
				return { left: l, top: t };
			} else {
				return { left: d.scrollLeft, top: d.scrollTop };
			}
		},

		getColor: function (attr, defaultValue, prefix) {
			var v = this.getStyle(attr);
			if (!v || v == "transparent" || v == "inherit") {
				return defaultValue;
			}
			var color = typeof prefix == "undefined" ? "#" : prefix;
			if (v.substr(0, 4) == "rgb(") {
				var rvs = v.slice(4, v.length - 1).split(",");
				for (var i = 0; i < 3; i++) {
					var h = parseInt(rvs[i]);
					var s = h.toString(16);
					if (h < 16) {
						s = "0" + s;
					}
					color += s;
				}
			} else {
				if (v.substr(0, 1) == "#") {
					if (v.length == 4) {
						for (var i = 1; i < 4; i++) {
							var c = v.charAt(i);
							color += c + c;
						}
					} else if (v.length == 7) {
						color += v.substr(1);
					}
				}
			}
			return (color.length > 5 ? color.toLowerCase() : defaultValue);
		},

		boxWrap: function (cls) {
			cls = cls || 'x-box';
			var el = Ext.get(this.insertHtml('beforeBegin', String.format('<div class="{0}">' + El.boxMarkup + '</div>', cls)));
			el.child('.' + cls + '-mc').dom.appendChild(this.dom);
			return el;
		},

		getAttributeNS: (Ext.isIE && !Ext.isIE9) ? function (ns, name) {
			var d = this.dom;
			var type = typeof d[ns + ":" + name];
			if (type != 'undefined' && type != 'unknown') {
				return d[ns + ":" + name];
			}
			return d[name];
		} : function (ns, name) {
			var d = this.dom;
			return d.getAttributeNS(ns, name) || d.getAttribute(ns + ":" + name) || d.getAttribute(name) || d[name];
		},

		getTextWidth: function (text, min, max) {
			var width = Ext.util.TextMetrics.measure(this.dom, Ext.value(text, this.dom.innerHTML, true)).width;
			if (Ext.isIE9) {
				width += 1;
			}
			return width.constrain(min || 0, max || 1000000);
		}
	};

	var ep = El.prototype;


	ep.on = ep.addListener;
	ep.mon = ep.addListener;

	ep.getUpdateManager = ep.getUpdater;


	ep.un = ep.removeListener;


	ep.autoBoxAdjust = true;

	El.unitPattern = /\d+(px|em|%|en|ex|pt|in|cm|mm|pc)$/i;

	El.addUnits = function (v, defaultUnit) {
		if (v === "" || v == "auto") {
			return v;
		}
		if (v === undefined) {
			return '';
		}
		if (typeof v == "number" || !El.unitPattern.test(v)) {
			return v + (defaultUnit || 'px');
		}
		return v;
	};

	El.unitParsePattern = /(\d+)\s*(.*)/;

	El.parseUnits = function (units) {
		var result = units.match(El.unitParsePattern);
		return result == null ? null : { value: result[1], measure: result[2] };
	};

	//El.boxMarkup = '<div class="{0}-tl"><div class="{0}-tr"><div class="{0}-tc"></div></div></div><div class="{0}-ml"><div class="{0}-mr"><div class="{0}-mc"></div></div></div><div class="{0}-bl"><div class="{0}-br"><div class="{0}-bc"></div></div></div>';
	El.boxMarkup = '<div class="{0}-tc"></div><div class="{0}-mc"></div><div class="{0}-bc"></div>';

	El.VISIBILITY = 1;

	El.DISPLAY = 2;

	El.borders = { l: "border-left-width", r: "border-right-width", t: "border-top-width", b: "border-bottom-width" };
	El.paddings = { l: "padding-left", r: "padding-right", t: "padding-top", b: "padding-bottom" };
	El.margins = { l: "margin-left", r: "margin-right", t: "margin-top", b: "margin-bottom" };




	El.cache = {};

	var docEl;


	El.get = function (el) {
		var ex, elm, id;
		if (!el) { return null; }
		if (typeof el == "string") {
			if (!(elm = document.getElementById(el))) {
				return null;
			}
			if (ex = El.cache[el]) {
				ex.dom = elm;
			} else {
				ex = El.cache[el] = new El(elm);
			}
			return ex;
		} else if (el.tagName) {
			if (!(id = el.id)) {
				id = Ext.id(el);
			}
			if (ex = El.cache[id]) {
				ex.dom = el;
			} else {
				ex = El.cache[id] = new El(el);
			}
			return ex;
		} else if (el instanceof El) {
			if (el != docEl) {
				el.dom = document.getElementById(el.id) || el.dom; El.cache[el.id] = el;
			}
			return el;
		} else if (el.isComposite) {
			return el;
		} else if (Ext.isArray(el)) {
			return El.select(el);
		} else if (el == document) {
			if (!docEl) {
				var f = function () { };
				f.prototype = El.prototype;
				docEl = new f();
				docEl.dom = document;
			}
			return docEl;
		}
		return null;
	};

	El.uncache = function (el) {
		for (var i = 0, a = arguments, len = a.length; i < len; i++) {
			if (a[i]) {
				delete El.cache[a[i].id || a[i]];
			}
		}
	};

	El.garbageCollect = function () {
		if (!Ext.enableGarbageCollector) {
			clearInterval(El.collectorThread);
			return;
		}
		for (var eid in El.cache) {
			var el = El.cache[eid], d = el.dom;
			if (!d || !d.parentNode || (!d.offsetParent && !document.getElementById(eid))) {
				delete El.cache[eid];
				if (d && Ext.enableListenerCollection) {
					Ext.EventManager.removeAll(d);
				}
			}
		}
	}
	El.collectorThreadId = setInterval(El.garbageCollect, 30000);

	var flyFn = function () { };
	flyFn.prototype = El.prototype;
	var _cls = new flyFn();

	El.Flyweight = function (dom) {
		this.dom = dom;
	};

	El.Flyweight.prototype = _cls;
	El.Flyweight.prototype.isFlyweight = true;

	El._flyweights = {};

	El.fly = function (el, named) {
		named = named || '_global';
		el = Ext.getDom(el);
		if (!el) {
			return null;
		}
		if (!El._flyweights[named]) {
			El._flyweights[named] = new El.Flyweight();
		}
		El._flyweights[named].dom = el;
		return El._flyweights[named];
	};


	Ext.get = El.get;

	Ext.fly = El.fly;

	var noBoxAdjust = Ext.isStrict ? {
		select: 1
	} : {
		input: 1, select: 1, textarea: 1
	};
	if (Ext.isIE || Ext.isGecko) {
		noBoxAdjust['button'] = 1;
	}


	Ext.EventManager.on(window, 'unload', function () {
		var el;
		for (el in Ext.Element.cache) {
			Ext.EventManager.removeAll(el);
		}
		delete El.cache;
		delete El._flyweights;
	});
})();

Ext.enableFx = true;

Ext.Fx = {
	slideIn: function (anchor, o) {
		var el = this.getFxEl();
		o = o || {};

		el.queueFx(o, function () {
			anchor = anchor || "t";
			this.fixDisplay();
			var r = this.getFxRestore();
			var b = this.getBox();
			this.setSize(b);
			var wrap = this.fxWrap(r.pos, o, "hidden");
			var st = this.dom.style;
			st.visibility = "visible";
			st.position = "absolute";

			var after = function () {
				el.fxUnwrap(wrap, r.pos, o);
				st.width = r.width;
				st.height = r.height;
				el.afterFx(o);
			};

			var a, pt = { to: [b.x, b.y] }, bw = { to: b.width }, bh = { to: b.height };

			switch (anchor.toLowerCase()) {
				case "t":
					wrap.setSize(b.width, 0);
					st.left = st.bottom = "0";
					a = { height: bh };
					break;
				case "l":
					wrap.setSize(0, b.height);
					st.right = st.top = "0";
					a = { width: bw };
					break;
				case "r":
					wrap.setSize(0, b.height);
					wrap.setX(b.right);
					st.left = st.top = "0";
					a = { width: bw, points: pt };
					break;
				case "b":
					wrap.setSize(b.width, 0);
					wrap.setY(b.bottom);
					st.left = st.top = "0";
					a = { height: bh, points: pt };
					break;
				case "tl":
					wrap.setSize(0, 0);
					st.right = st.bottom = "0";
					a = { width: bw, height: bh };
					break;
				case "bl":
					wrap.setSize(0, 0);
					wrap.setY(b.y + b.height);
					st.right = st.top = "0";
					a = { width: bw, height: bh, points: pt };
					break;
				case "br":
					wrap.setSize(0, 0);
					wrap.setXY([b.right, b.bottom]);
					st.left = st.top = "0";
					a = { width: bw, height: bh, points: pt };
					break;
				case "tr":
					wrap.setSize(0, 0);
					wrap.setX(b.x + b.width);
					st.left = st.bottom = "0";
					a = { width: bw, height: bh, points: pt };
					break;
			}
			this.dom.style.visibility = "visible";
			wrap.show();
			arguments.callee.anim = wrap.fxanim(a, o, 'motion', .5, 'easeOut', after);
		});
		return this;
	},

	slideOut: function (anchor, o) {
		var el = this.getFxEl();
		o = o || {};

		el.queueFx(o, function () {
			anchor = anchor || "t";
			var r = this.getFxRestore();
			var b = this.getBox();
			this.setSize(b);
			var wrap = this.fxWrap(r.pos, o, "visible");
			var st = this.dom.style;
			st.visibility = "visible";
			st.position = "absolute";
			wrap.setSize(b);

			var after = function () {
				if (o.useDisplay) {
					el.setDisplayed(false);
				} else {
					el.hide();
				}
				el.fxUnwrap(wrap, r.pos, o);
				st.width = r.width;
				st.height = r.height;
				el.afterFx(o);
			};

			var a, zero = { to: 0 };
			switch (anchor.toLowerCase()) {
				case "t":
					st.left = st.bottom = "0";
					a = { height: zero };
					break;
				case "l":
					st.right = st.top = "0";
					a = { width: zero };
					break;
				case "r":
					st.left = st.top = "0";
					a = { width: zero, points: { to: [b.right, b.y]} };
					break;
				case "b":
					st.left = st.top = "0";
					a = { height: zero, points: { to: [b.x, b.bottom]} };
					break;
				case "tl":
					st.right = st.bottom = "0";
					a = { width: zero, height: zero };
					break;
				case "bl":
					st.right = st.top = "0";
					a = { width: zero, height: zero, points: { to: [b.x, b.bottom]} };
					break;
				case "br":
					st.left = st.top = "0";
					a = { width: zero, height: zero, points: { to: [b.x + b.width, b.bottom]} };
					break;
				case "tr":
					st.left = st.bottom = "0";
					a = { width: zero, height: zero, points: { to: [b.right, b.y]} };
					break;
			}

			arguments.callee.anim = wrap.fxanim(a, o, 'motion', .5, "easeOut", after);
		});
		return this;
	},

	puff: function (o) {
		var el = this.getFxEl();
		o = o || {};

		el.queueFx(o, function () {
			this.clearOpacity();
			this.show();
			var r = this.getFxRestore();
			var st = this.dom.style;

			var after = function () {
				if (o.useDisplay) {
					el.setDisplayed(false);
				} else {
					el.hide();
				}
				el.clearOpacity();
				el.setPositioning(r.pos);
				st.width = r.width;
				st.height = r.height;
				st.fontSize = '';
				el.afterFx(o);
			};

			var width = this.getWidth();
			var height = this.getHeight();

			arguments.callee.anim = this.fxanim({
				width: { to: this.adjustWidth(width * 2) },
				height: { to: this.adjustHeight(height * 2) },
				points: { by: [-(width * .5), -(height * .5)] },
				opacity: { to: 0 },
				fontSize: { to: 200, unit: "%" }
			},
			o, 'motion', .5, "easeOut", after);
		});
		return this;
	},

	switchOff: function (o) {
		var el = this.getFxEl();
		o = o || {};

		el.queueFx(o, function () {
			this.clearOpacity();
			this.clip();

			var r = this.getFxRestore();
			var st = this.dom.style;

			var after = function () {
				if (o.useDisplay) {
					el.setDisplayed(false);
				} else {
					el.hide();
				}
				el.clearOpacity();
				el.setPositioning(r.pos);
				st.width = r.width;
				st.height = r.height;
				el.afterFx(o);
			};

			this.fxanim({ opacity: { to: 0.3} }, null, null, .1, null, function () {
				this.clearOpacity();
				(function () {
					this.fxanim({
						height: { to: 1 },
						points: { by: [0, this.getHeight() * .5] }
					}, o, 'motion', 0.3, 'easeIn', after);
				}).defer(100, this);
			});
		});
		return this;
	},

	highlight: function (color, o) {
		var el = this.getFxEl();
		o = o || {};

		el.queueFx(o, function () {
			color = color || "ffff9c";
			var attr = o.attr || "backgroundColor";
			this.clearOpacity();
			this.show();
			var origColor = this.getColor(attr);
			var restoreColor = this.dom.style[attr];
			var endColor = (o.endColor || origColor) || "ffffff";

			var after = function () {
				el.dom.style[attr] = restoreColor;
				el.afterFx(o);
			};

			var a = {};
			a[attr] = { from: color, to: endColor };
			arguments.callee.anim = this.fxanim(a, o, 'color', 1, 'easeIn', after);
		});
		return this;
	},

	frame: function (color, count, o) {
		var el = this.getFxEl();
		o = o || {};

		el.queueFx(o, function () {
			color = color || "#C3DAF9";
			if (color.length == 6) {
				color = "#" + color;
			}
			count = count || 1;
			var duration = o.duration || 1;
			this.show();
			var b = this.getBox();

			var animFn = function () {
				var proxy = Ext.getBody().createChild({
					style: {
						visbility: "hidden",
						position: "absolute",
						"z-index": "35000", border: "0px solid " + color
					}
				});

				var scale = Ext.isBorderBox ? 2 : 1;
				proxy.animate({
					top: { from: b.y, to: b.y - 20 },
					left: { from: b.x, to: b.x - 20 },
					borderWidth: { from: 0, to: 10 },
					opacity: { from: 1, to: 0 },
					height: { from: b.height, to: (b.height + (20 * scale)) },
					width: { from: b.width, to: (b.width + (20 * scale)) }
				}, duration, function () {
					proxy.remove();
					if (--count > 0) {
						animFn();
					} else {
						el.afterFx(o);
					}
				});
			};
			animFn.call(this);
		});
		return this;
	},

	pause: function (seconds) {
		var el = this.getFxEl();
		var o = {};

		el.queueFx(o, function () {
			setTimeout(function () {
				el.afterFx(o);
			}, seconds * 1000);
		});
		return this;
	},

	fadeIn: function (o) {
		var el = this.getFxEl();
		o = o || {};

		el.queueFx(o, function () {
			this.setOpacity(0);
			this.fixDisplay();
			this.dom.style.visibility = 'visible';
			var to = o.endOpacity || 1;
			arguments.callee.anim = this.fxanim({ opacity: { to: to} },
			o, null, .5, "easeOut", function () {
				if (to == 1) {
					this.clearOpacity();
				}
				el.afterFx(o);
			});
		});
		return this;
	},

	fadeOut: function (o) {
		var el = this.getFxEl();
		o = o || {};
		el.queueFx(o, function () {
			arguments.callee.anim = this.fxanim({ opacity: { to: o.endOpacity || 0} },
			o, null, .5, "easeOut", function () {
				if (this.visibilityMode == Ext.Element.DISPLAY || o.useDisplay) {
					this.dom.style.display = "none";
				} else {
					this.dom.style.visibility = "hidden";
				}
				this.clearOpacity();
				el.afterFx(o);
			});
		});
		return this;
	},

	scale: function (w, h, o) {
		this.shift(Ext.apply({}, o, {
			width: w,
			height: h
		}));
		return this;
	},

	shift: function (o) {
		var el = this.getFxEl();
		o = o || {};
		el.queueFx(o, function () {
			var a = {}, w = o.width, h = o.height, x = o.x, y = o.y, op = o.opacity;
			if (w !== undefined) {
				a.width = { to: this.adjustWidth(w) };
			}
			if (h !== undefined) {
				a.height = { to: this.adjustHeight(h) };
			}
			if (o.left !== undefined) {
				a.left = { to: o.left };
			}
			if (o.top !== undefined) {
				a.top = { to: o.top };
			}
			if (o.right !== undefined) {
				a.right = { to: o.right };
			}
			if (o.bottom !== undefined) {
				a.bottom = { to: o.bottom };
			}
			if (x !== undefined || y !== undefined) {
				a.points = { to: [
				x !== undefined ? x : this.getX(),
				y !== undefined ? y : this.getY()
			]
				};
			}
			if (op !== undefined) {
				a.opacity = { to: op };
			}
			if (o.xy !== undefined) {
				a.points = { to: o.xy };
			}
			arguments.callee.anim = this.fxanim(a,
			o, 'motion', .35, "easeOut", function () {
				el.afterFx(o);
			});
		});
		return this;
	},

	ghost: function (anchor, o) {
		var el = this.getFxEl();
		o = o || {};

		el.queueFx(o, function () {
			anchor = anchor || "b";

			var r = this.getFxRestore();
			var w = this.getWidth(),
			h = this.getHeight();

			var st = this.dom.style;

			var after = function () {
				if (o.useDisplay) {
					el.setDisplayed(false);
				} else {
					el.hide();
				}

				el.clearOpacity();
				el.setPositioning(r.pos);
				st.width = r.width;
				st.height = r.height;

				el.afterFx(o);
			};

			var a = { opacity: { to: 0 }, points: {} }, pt = a.points;
			switch (anchor.toLowerCase()) {
				case "t":
					pt.by = [0, -h];
					break;
				case "l":
					pt.by = [-w, 0];
					break;
				case "r":
					pt.by = [w, 0];
					break;
				case "b":
					pt.by = [0, h];
					break;
				case "tl":
					pt.by = [-w, -h];
					break;
				case "bl":
					pt.by = [-w, h];
					break;
				case "br":
					pt.by = [w, h];
					break;
				case "tr":
					pt.by = [w, -h];
					break;
			}

			arguments.callee.anim = this.fxanim(a,
			o,
			'motion',
			.5,
			"easeOut", after);
		});
		return this;
	},

	syncFx: function () {
		this.fxDefaults = Ext.apply(this.fxDefaults || {}, {
			block: false,
			concurrent: true,
			stopFx: false
		});
		return this;
	},

	sequenceFx: function () {
		this.fxDefaults = Ext.apply(this.fxDefaults || {}, {
			block: false,
			concurrent: false,
			stopFx: false
		});
		return this;
	},

	nextFx: function () {
		var ef = this.fxQueue[0];
		if (ef) {
			ef.call(this);
		}
	},

	hasActiveFx: function () {
		return this.fxQueue && this.fxQueue[0];
	},

	stopFx: function () {
		if (this.hasActiveFx()) {
			var cur = this.fxQueue[0];
			if (cur && cur.anim && cur.anim.isAnimated()) {
				this.fxQueue = [cur]; cur.anim.stop(true);
			}
		}
		return this;
	},

	beforeFx: function (o) {
		if (this.hasActiveFx() && !o.concurrent) {
			if (o.stopFx) {
				this.stopFx();
				return true;
			}
			return false;
		}
		return true;
	},

	hasFxBlock: function () {
		var q = this.fxQueue;
		return q && q[0] && q[0].block;
	},

	queueFx: function (o, fn) {
		if (!this.fxQueue) {
			this.fxQueue = [];
		}
		if (!this.hasFxBlock()) {
			Ext.applyIf(o, this.fxDefaults);
			if (!o.concurrent) {
				var run = this.beforeFx(o);
				fn.block = o.block;
				this.fxQueue.push(fn);
				if (run) {
					this.nextFx();
				}
			} else {
				fn.call(this);
			}
		}
		return this;
	},

	fxWrap: function (pos, o, vis) {
		var wrap;
		if (!o.wrap || !(wrap = Ext.get(o.wrap))) {
			var wrapXY;
			if (o.fixPosition) {
				wrapXY = this.getXY();
			}
			var div = document.createElement("div");
			div.style.visibility = vis;
			wrap = Ext.get(this.dom.parentNode.insertBefore(div, this.dom));
			wrap.setPositioning(pos);
			if (wrap.getStyle("position") == "static") {
				wrap.position("relative");
			}
			this.clearPositioning('auto');
			wrap.clip();
			wrap.dom.appendChild(this.dom);
			if (wrapXY) {
				wrap.setXY(wrapXY);
			}
		}
		return wrap;
	},

	fxUnwrap: function (wrap, pos, o) {
		this.clearPositioning();
		this.setPositioning(pos);
		if (!o.wrap) {
			wrap.dom.parentNode.insertBefore(this.dom, wrap.dom);
			wrap.remove();
		}
	},

	getFxRestore: function () {
		var st = this.dom.style;
		return { pos: this.getPositioning(), width: st.width, height: st.height };
	},

	afterFx: function (o) {
		if (o.afterStyle) {
			this.applyStyles(o.afterStyle);
		}
		if (o.afterCls) {
			this.addClass(o.afterCls);
		}
		if (o.remove === true) {
			this.remove();
		}
		Ext.callback(o.callback, o.scope, [this]);
		if (!o.concurrent) {
			this.fxQueue.shift();
			this.nextFx();
		}
	},

	getFxEl: function () {
		return Ext.get(this.dom);
	},

	fxanim: function (args, opt, animType, defaultDur, defaultEase, cb) {
		animType = animType || 'run';
		opt = opt || {};
		var anim = Ext.lib.Anim[animType](
			this.dom, args,
			(opt.duration || defaultDur) || .35,
			(opt.easing || defaultEase) || 'easeOut',

			function () {
				Ext.callback(cb, this);
			},
			this
		);
		opt.anim = anim;
		return anim;
	}
};

Ext.Fx.resize = Ext.Fx.scale;

Ext.apply(Ext.Element.prototype, Ext.Fx);

Ext.CompositeElement = function (els) {
	this.elements = [];
	this.addElements(els);
};

Ext.CompositeElement.prototype = {
	isComposite: true,
	addElements: function (els) {
		if (!els) return this;
		if (typeof els == "string") {
			els = Ext.Element.selectorFunction(els);
		}
		var yels = this.elements;
		var index = yels.length - 1;
		for (var i = 0, len = els.length; i < len; i++) {
			yels[++index] = Ext.get(els[i]);
		}
		return this;
	},

	fill: function (els) {
		this.elements = [];
		this.add(els);
		return this;
	},

	filter: function (selector) {
		var els = [];
		this.each(function (el) {
			if (el.is(selector)) {
				els[els.length] = el.dom;
			}
		});
		this.fill(els);
		return this;
	},

	invoke: function (fn, args) {
		var els = this.elements;
		for (var i = 0, len = els.length; i < len; i++) {
			Ext.Element.prototype[fn].apply(els[i], args);
		}
		return this;
	},

	add: function (els) {
		if (typeof els == "string") {
			this.addElements(Ext.Element.selectorFunction(els));
		} else if (els.length !== undefined) {
			this.addElements(els);
		} else {
			this.addElements([els]);
		}
		return this;
	},

	each: function (fn, scope) {
		var els = this.elements;
		for (var i = 0, len = els.length; i < len; i++) {
			if (fn.call(scope || els[i], els[i], this, i) === false) {
				break;
			}
		}
		return this;
	},

	item: function (index) {
		return this.elements[index] || null;
	},

	first: function () {
		return this.item(0);
	},

	last: function () {
		return this.item(this.elements.length - 1);
	},

	getCount: function () {
		return this.elements.length;
	},

	contains: function (el) {
		return this.indexOf(el) !== -1;
	},

	indexOf: function (el) {
		return this.elements.indexOf(Ext.get(el));
	},

	removeElement: function (el, removeDom) {
		if (Ext.isArray(el)) {
			for (var i = 0, len = el.length; i < len; i++) {
				this.removeElement(el[i]);
			}
			return this;
		}
		var index = typeof el == 'number' ? el : this.indexOf(el);
		if (index !== -1 && this.elements[index]) {
			if (removeDom) {
				var d = this.elements[index];
				if (d.dom) {
					d.remove();
				} else {
					Ext.removeNode(d);
				}
			}
			this.elements.splice(index, 1);
		}
		return this;
	},

	replaceElement: function (el, replacement, domReplace) {
		var index = typeof el == 'number' ? el : this.indexOf(el);
		if (index !== -1) {
			if (domReplace) {
				this.elements[index].replaceWith(replacement);
			} else {
				this.elements.splice(index, 1, Ext.get(replacement))
			}
		}
		return this;
	},

	clear: function () {
		this.elements = [];
	}
};

(function () {
	Ext.CompositeElement.createCall = function (proto, fnName) {
		if (!proto[fnName]) {
			proto[fnName] = function () {
				return this.invoke(fnName, arguments);
			};
		}
	};
	for (var fnName in Ext.Element.prototype) {
		if (typeof Ext.Element.prototype[fnName] == "function") {
			Ext.CompositeElement.createCall(Ext.CompositeElement.prototype, fnName);
		}
	};
})();

Ext.CompositeElementLite = function (els) {
	Ext.CompositeElementLite.superclass.constructor.call(this, els);
	this.el = new Ext.Element.Flyweight();
};

Ext.extend(Ext.CompositeElementLite, Ext.CompositeElement, {
	addElements: function (els) {
		if (els) {
			if (Ext.isArray(els)) {
				this.elements = this.elements.concat(els);
			} else {
				var yels = this.elements;
				var index = yels.length - 1;
				for (var i = 0, len = els.length; i < len; i++) {
					yels[++index] = els[i];
				}
			}
		}
		return this;
	},

	invoke: function (fn, args) {
		var els = this.elements;
		var el = this.el;
		for (var i = 0, len = els.length; i < len; i++) {
			el.dom = els[i];
			Ext.Element.prototype[fn].apply(el, args);
		}
		return this;
	},

	item: function (index) {
		if (!this.elements[index]) {
			return null;
		}
		this.el.dom = this.elements[index];
		return this.el;
	},

	addListener: function (eventName, handler, scope, opt) {
		var els = this.elements;
		for (var i = 0, len = els.length; i < len; i++) {
			Ext.EventManager.on(els[i], eventName, handler, scope || els[i], opt);
		}
		return this;
	},

	each: function (fn, scope) {
		var els = this.elements;
		var el = this.el;
		for (var i = 0, len = els.length; i < len; i++) {
			el.dom = els[i];
			if (fn.call(scope || el, el, this, i) === false) {
				break;
			}
		}
		return this;
	},

	indexOf: function (el) {
		return this.elements.indexOf(Ext.getDom(el));
	},

	replaceElement: function (el, replacement, domReplace) {
		var index = typeof el == 'number' ? el : this.indexOf(el);
		if (index !== -1) {
			replacement = Ext.getDom(replacement);
			if (domReplace) {
				var d = this.elements[index];
				d.parentNode.insertBefore(replacement, d);
				Ext.removeNode(d);
			}
			this.elements.splice(index, 1, replacement);
		}
		return this;
	}
});

Ext.CompositeElementLite.prototype.on = Ext.CompositeElementLite.prototype.addListener;
if (Ext.DomQuery) {
	Ext.Element.selectorFunction = Ext.DomQuery.select;
}

Ext.Element.select = function (selector, unique, root) {
	var els;
	if (typeof selector == "string") {
		els = Ext.Element.selectorFunction(selector, root);
	} else if (selector.length !== undefined) {
		els = selector;
	} else {
		throw " ";
	}
	if (unique === true) {
		return new Ext.CompositeElement(els);
	} else {
		return new Ext.CompositeElementLite(els);
	}
};

Ext.select = Ext.Element.select;

Ext.data.Connection = function (config) {
	Ext.apply(this, config);
	this.addEvents(
		"beforerequest",
		"requestcomplete",
		"requestexception"
	);
	Ext.data.Connection.superclass.constructor.call(this);
};

Ext.extend(Ext.data.Connection, Ext.util.Observable, {
	timeout: 120000,
	autoAbort: false,
	disableCaching: true,
	disableCachingParam: '_dc',
	syncQueue: [],
	processingSyncRequest: false,
	csrfCookieName: "BPMCSRF",

	request: function (o) {
		if (o.async == false) {
			return this.processSyncRequest(o);
		}
		return this.internalRequest(o);
	},

	internalRequest: function (o) {
		if (o.async == false) {
			this.processingSyncRequest = true;
		}
		if (this.fireEvent("beforerequest", this, o) !== false) {
			var p = o.params;
			if (typeof p == "function") {
				p = p.call(o.scope || window, o);
			}
			if (typeof p == "object") {
				var submitAjaxEventConfig = p.submitAjaxEventConfig;
				if (typeof submitAjaxEventConfig == 'string') {
					p.submitAjaxEventConfig = Ext.util.Format.htmlEncode(submitAjaxEventConfig);
				}
				p = Ext.urlEncode(p);
			}
			var extraParams = this.extraParams || o.extraParams;
			if (extraParams) {
				var extras = Ext.urlEncode(this.extraParams);
				p = p ? (p + '&' + extras) : extras;
			}
			var url = o.url || this.url;
			if (typeof url == 'function') {
				url = url.call(o.scope || window, o);
			}
			if (o.form) {
				var form = Ext.getDom(o.form);
				url = url || form.action;
				var enctype = form.getAttribute("enctype");
				if (o.isUpload || (enctype && enctype.toLowerCase() == 'multipart/form-data')) {
					return this.doFormUpload(o, p, url);
				}
				var f = Ext.lib.Ajax.serializeForm(form);
				p = p ? (p + '&' + f) : f;
			}
			var hs = o.headers;
			if (this.defaultHeaders) {
				hs = Ext.apply(hs || {}, this.defaultHeaders);
				if (!o.headers) {
					o.headers = hs;
				}
			}
			var headerWithCsrfToken = this.getCsrfTokenIfExists();
			o.headers = Ext.apply(o.headers || {}, headerWithCsrfToken);
			var cb = {
				success: this.handleResponse,
				failure: this.handleFailure,
				scope: this,
				argument: { options: o },
				timeout: o.timeout || this.timeout
			};
			var method = o.method || this.method || ((p || o.xmlData || o.jsonData) ? "POST" : "GET");
			if (method == 'GET' && (this.disableCaching && o.disableCaching !== false) || o.disableCaching === true) {
				var dcp = o.disableCachingParam || this.disableCachingParam;
				url += (url.indexOf('?') != -1 ? '&' : '?') + dcp + '=' + (new Date().getTime());
			}
			if (typeof o.autoAbort == 'boolean') {
				if (o.autoAbort) {
					this.abort();
				}
			} else if (this.autoAbort !== false) {
				this.abort();
			}
			if ((method == 'GET' || o.xmlData || o.jsonData) && p) {
				url += (url.indexOf('?') != -1 ? '&' : '?') + p;
				p = '';
			}
			this.transId = Ext.lib.Ajax.request(method, url, cb, p, o);
			if (o.scope.maskEl) {
				this.transId.maskEl = o.scope.maskEl;
			}
			return this.transId;
		} else {
			Ext.callback(o.callback, o.scope, [o, null, null]);
			return null;
		}
	},

	getCsrfTokenIfExists: function () {
		var cookie = document.cookie;
		var cookieArray = cookie.split("; ");
		var csrfCookieName = this.csrfCookieName;
		var headers={};
		cookieArray.forEach(function(cookie) {
			var valueArray = cookie.split("=");
			if (valueArray[0] === csrfCookieName) {
				headers[csrfCookieName] = valueArray[1];
				return false;
			}
		});
		return headers;
	},

	getInputElementWithCsrfToken: function () {
		var csrfHeader = this.getCsrfTokenIfExists();
		var element = document.createElement('input');
		element.type = 'hidden';
		element.name = this.csrfCookieName;
		element.value = csrfHeader[this.csrfCookieName];
		return element;
	},

	isLoading: function (transId) {
		if (transId) {
			return Ext.lib.Ajax.isCallInProgress(transId);
		} else {
			return this.transId ? true : false;
		}
	},

	abort: function (transId) {
		if (transId || this.isLoading()) {
			Ext.lib.Ajax.abort(transId || this.transId);
		}
	},

	handleResponse: function (response) {
		this.transId = false;
		var options = response.argument.options;
		response.argument = options ? options.argument : null;
		this.fireEvent("requestcomplete", this, response, options);
		Ext.callback(options.success, options.scope, [response, options]);
		Ext.callback(options.callback, options.callbackScope, [options, true, response]);
		if (options.async == false) {
			this.processingSyncRequest = false;
			this.processSyncRequestQueue();
		}
	},

	handleFailure: function (response, e) {
		this.transId = false;
		var options = response.argument.options;
		response.argument = options ? options.argument : null;
		this.fireEvent("requestexception", this, response, options, e);
		Ext.callback(options.failure, options.scope, [response, options]);
		Ext.callback(options.callback, options.callbackScope, [options, false, response]);
		if (options.async == false) {
			this.processingSyncRequest = false;
			this.processSyncRequestQueue();
		}
	},

	doFormUpload: function (o, ps, url) {
		var id = Ext.id();
		var frame = document.createElement('iframe');
		frame.id = id;
		frame.name = id;
		frame.className = 'x-hidden';
		if (Ext.isIE) {
			frame.src = Ext.SSL_SECURE_URL;
		}
		document.body.appendChild(frame);
		if (Ext.isIE) {
			document.frames[id].name = id;
		}
		var form = Ext.getDom(o.form);
		form.target = id;
		form.method = 'POST';
		form.enctype = form.encoding = 'multipart/form-data';
		if (url) {
			form.action = url;
		}
		var processPostData = function (isEncode) {
			for (var i = 0; i < form.elements.length; i++) {
				var element = form.elements[i];
				if (!element || element.type == 'file') {
					continue;
				}
				var elementValue = element.value;
				var elementName = element.name;
				if (element.disabled !== true && elementName && element.name != "__VIEWSTATE" &&
							!Ext.isEmpty(elementValue)) {
					element.value =
							Ext.util.Format[(isEncode === true) ? 'htmlEncode' : 'htmlDecode'](elementValue);
				}
			}
		}
		processPostData(true);
		var hiddens, hd;
		if (ps) {
			hiddens = [];
			ps = Ext.urlDecode(ps, false);
			for (var k in ps) {
				if (ps.hasOwnProperty(k)) {
					hd = document.createElement('input');
					hd.type = 'hidden';
					hd.name = k;
					hd.value = ps[k];
					form.appendChild(hd);
					hiddens.push(hd);
				}
			}
		}
		//var connection = this;
		function cb() {
			var r = { responseText: '',
				responseXML: null
			};
			r.argument = o ? o.argument : null;
			try {
				var doc;
				if (Ext.isIE) {
					doc = frame.contentWindow.document;
				} else {
					doc = (frame.contentDocument || window.frames[id].document);
				}
				if (doc && doc.body) {
					r.responseText = Ext.util.Format.htmlDecode(doc.body.innerHTML);
				}
				if (doc && doc.XMLDocument) {
					r.responseXML = doc.XMLDocument;
				} else {
					r.responseXML = doc;
				}
			}
			catch (e) {
			}
			Ext.EventManager.removeListener(frame, 'load', cb, this);
			this.fireEvent("requestcomplete", this, r, o);
			processPostData(false);
			Ext.callback(o.success, o.scope, [r, o]);
			Ext.callback(o.callback, o.callbackScope, [o, true, r]);
			setTimeout(function () { Ext.removeNode(frame); }, 100);
		}
		Ext.EventManager.on(frame, 'load', cb, this);
		/*
		if (Ext.isIE) {
		frame.attachEvent('onload', cb);
		} else {
		frame.onload = cb;
		}
		*/
		if (form.elements[this.csrfCookieName]) {
			var csrfHeader = this.getCsrfTokenIfExists();
			form.elements[this.csrfCookieName].value = csrfHeader[this.csrfCookieName];
		} else {
			form.appendChild(this.getInputElementWithCsrfToken());
		}
		form.submit();
		form.setAttribute('enctype', '');
		processPostData(false);
		if (hiddens) {
			for (var i = 0, len = hiddens.length; i < len; i++) {
				Ext.removeNode(hiddens[i]);
			}
		}
	},

	processSyncRequest: function (o) {
		if (this.processingSyncRequest) {
			this.syncQueue.push(o);
			return false;
		}
		return this.internalRequest(o);
	},

	processSyncRequestQueue: function () {
		if (this.syncQueue.length == 0) {
			return;
		}
		var o = this.syncQueue[0];
		this.internalRequest(o);
		this.syncQueue.shift();
	}
});

Ext.Ajax = new Ext.data.Connection({
	autoAbort: false,

	serializeForm: function (form) {
		return Ext.lib.Ajax.serializeForm(form);
	}
});

Ext.Updater = Ext.extend(Ext.util.Observable, {
	constructor: function (el, forceNew) {
		el = Ext.get(el);
		if (!forceNew && el.updateManager) {
			return el.updateManager;
		}
		this.el = el;
		this.defaultUrl = null;
		this.addEvents(
			"beforeupdate",
			"update",
			"failure"
		);
		var d = Ext.Updater.defaults;
		this.sslBlankUrl = d.sslBlankUrl;
		this.disableCaching = d.disableCaching;
		this.indicatorText = d.indicatorText;
		this.showLoadIndicator = d.showLoadIndicator;
		this.timeout = d.timeout;
		this.loadScripts = d.loadScripts;
		this.transaction = null;
		this.refreshDelegate = this.refresh.createDelegate(this);
		this.updateDelegate = this.update.createDelegate(this);
		this.formUpdateDelegate = this.formUpdate.createDelegate(this);
		if (!this.renderer) {
			this.renderer = this.getDefaultRenderer();
		}
		Ext.Updater.superclass.constructor.call(this);
	},

	getDefaultRenderer: function () {
		return new Ext.Updater.BasicRenderer();
	},

	getEl: function () {
		return this.el;
	},

	update: function (url, params, callback, discardUrl) {
		if (this.fireEvent("beforeupdate", this.el, url, params) !== false) {
			var cfg, callerScope;
			if (typeof url == "object") {
				cfg = url;
				url = cfg.url;
				params = params || cfg.params;
				callback = callback || cfg.callback;
				discardUrl = discardUrl || cfg.discardUrl;
				callerScope = cfg.scope;
				if (typeof cfg.nocache != "undefined") { this.disableCaching = cfg.nocache; };
				if (typeof cfg.text != "undefined") { this.indicatorText = '<div class="loading-indicator">' + cfg.text + "</div>"; };
				if (typeof cfg.scripts != "undefined") { this.loadScripts = cfg.scripts; };
				if (typeof cfg.timeout != "undefined") { this.timeout = cfg.timeout; };
			}
			this.showLoading();

			if (!discardUrl) {
				this.defaultUrl = url;
			}
			if (typeof url == "function") {
				url = url.call(this);
			}

			var o = Ext.apply({}, {
				url: url,
				params: (typeof params == "function" && callerScope) ? params.createDelegate(callerScope) : params,
				success: this.processSuccess,
				failure: this.processFailure,
				scope: this,
				callback: undefined,
				timeout: (this.timeout * 1000),
				disableCaching: this.disableCaching,
				argument: {
					"options": cfg,
					"url": url,
					"form": null,
					"callback": callback,
					"scope": callerScope || window,
					"params": params
				}
			}, cfg);

			this.transaction = Ext.Ajax.request(o);
		}
	},

	formUpdate: function (form, url, reset, callback) {
		if (this.fireEvent("beforeupdate", this.el, form, url) !== false) {
			if (typeof url == "function") {
				url = url.call(this);
			}
			form = Ext.getDom(form)
			this.transaction = Ext.Ajax.request({
				form: form,
				url: url,
				success: this.processSuccess,
				failure: this.processFailure,
				scope: this,
				timeout: (this.timeout * 1000),
				argument: {
					"url": url,
					"form": form,
					"callback": callback,
					"reset": reset
				}
			});
			this.showLoading.defer(1, this);
		}
	},

	refresh: function (callback) {
		if (this.defaultUrl == null) {
			return;
		}
		this.update(this.defaultUrl, null, callback, true);
	},

	startAutoRefresh: function (interval, url, params, callback, refreshNow) {
		if (refreshNow) {
			this.update(url || this.defaultUrl, params, callback, true);
		}
		if (this.autoRefreshProcId) {
			clearInterval(this.autoRefreshProcId);
		}
		this.autoRefreshProcId = setInterval(this.update.createDelegate(this, [url || this.defaultUrl, params, callback, true]), interval * 1000);
	},

	stopAutoRefresh: function () {
		if (this.autoRefreshProcId) {
			clearInterval(this.autoRefreshProcId);
			delete this.autoRefreshProcId;
		}
	},

	isAutoRefreshing: function () {
		return this.autoRefreshProcId ? true : false;
	},

	showLoading: function () {
		if (this.showLoadIndicator) {
			this.el.update(this.indicatorText);
		}
	},

	processSuccess: function (response) {
		this.transaction = null;
		if (response.argument.form && response.argument.reset) {
			try {
				response.argument.form.reset();
			} catch (e) { }
		}
		if (this.loadScripts) {
			this.renderer.render(this.el, response, this,
			this.updateComplete.createDelegate(this, [response]));
		} else {
			this.renderer.render(this.el, response, this);
			this.updateComplete(response);
		}
	},

	updateComplete: function (response) {
		this.fireEvent("update", this.el, response);
		if (typeof response.argument.callback == "function") {
			response.argument.callback.call(response.argument.scope, this.el, true, response, response.argument.options);
		}
	},

	processFailure: function (response) {
		this.transaction = null;
		this.fireEvent("failure", this.el, response);
		if (typeof response.argument.callback == "function") {
			response.argument.callback.call(response.argument.scope, this.el, false, response, response.argument.options);
		}
	},

	setRenderer: function (renderer) {
		this.renderer = renderer;
	},

	getRenderer: function () {
		return this.renderer;
	},

	setDefaultUrl: function (defaultUrl) {
		this.defaultUrl = defaultUrl;
	},

	abort: function () {
		if (this.transaction) {
			Ext.Ajax.abort(this.transaction);
		}
	},

	isUpdating: function () {
		if (this.transaction) {
			return Ext.Ajax.isLoading(this.transaction);
		}
		return false;
	}
});

Ext.Updater.defaults = {
	timeout: 30,
	loadScripts: false,
	sslBlankUrl: (Ext.SSL_SECURE_URL || "javascript:false"),
	disableCaching: false,
	showLoadIndicator: true,
	indicatorText: '<div class="loading-indicator">Загрузка...</div>'
};

Ext.Updater.updateElement = function (el, url, params, options) {
	var um = Ext.get(el).getUpdater();
	Ext.apply(um, options);
	um.update(url, params, options ? options.callback : null);
};

Ext.Updater.BasicRenderer = function () { };

Ext.Updater.BasicRenderer.prototype = {
	render: function (el, response, updateManager, callback) {
		el.update(response.responseText, updateManager.loadScripts, callback);
	}
};

Ext.UpdateManager = Ext.Updater;

(function () {
	Date.formatCodeToRegex = function (character, currentGroup) {
		var p = Date.parseCodes[character];

		if (p) {
			p = Ext.type(p) == 'function' ? p() : p;
			Date.parseCodes[character] = p;
		}
		return p ? Ext.applyIf({
			c: p.c ? String.format(p.c, currentGroup || "{0}") : p.c
		}, p) : {
			g: 0,
			c: null,
			s: Ext.escapeRe(character)
		}
	}

	var $f = Date.formatCodeToRegex;

	Ext.apply(Date, {
		parseFunctions: { count: 0 },
		parseRegexes: [],
		formatFunctions: { count: 0 },
		daysInMonth: [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31],
		y2kYear: 50,
		MILLI: "ms",
		SECOND: "s",
		MINUTE: "mi",
		HOUR: "h",
		DAY: "d",
		MONTH: "mo",
		YEAR: "y",
		dayNames: [
			"Воскресенье",
			"Понедельник",
			"Вторник",
			"Среда",
			"Четверг",
			"Пятница",
			"Суббота"
		],
		dayShortNames: [
			"Вс",
			"Пн",
			"Вт",
			"Ср",
			"Чт",
			"Пт",
			"Сб"
		],
		monthNames: [
			"Январь",
			"Февраль",
			"Март",
			"Апрель",
			"Май",
			"Июнь",
			"Июль",
			"Август",
			"Сентябрь",
			"Октябрь",
			"Ноябрь",
			"Декабрь"
		],
		monthNumbers: {
			Jan: 0,
			Feb: 1,
			Mar: 2,
			Apr: 3,
			May: 4,
			Jun: 5,
			Jul: 6,
			Aug: 7,
			Sep: 8,
			Oct: 9,
			Nov: 10,
			Dec: 11
		},

		getShortMonthName: function (month) {
			return Date.monthNames[month].substring(0, 3);
		},

		getShortDayName: function (day) {
			return Date.dayNames[day].substring(0, 3);
		},

		getMonthNumber: function (name) {
			return Date.monthNumbers[name.substring(0, 1).toUpperCase() + name.substring(1, 3).toLowerCase()];
		},

		formatCodes: {
			d: "String.leftPad(this.getDate(), 2, '0')",
			D: "Date.getShortDayName(this.getDay())", j: "this.getDate()",
			l: "Date.dayNames[this.getDay()]",
			N: "(this.getDay() ? this.getDay() : 7)",
			S: "this.getSuffix()",
			w: "this.getDay()",
			z: "this.getDayOfYear()",
			W: "String.leftPad(this.getWeekOfYear(), 2, '0')",
			F: "Date.monthNames[this.getMonth()]",
			m: "String.leftPad(this.getMonth() + 1, 2, '0')",
			M: "Date.getShortMonthName(this.getMonth())", n: "(this.getMonth() + 1)",
			t: "this.getDaysInMonth()",
			L: "(this.isLeapYear() ? 1 : 0)",
			o: "(this.getFullYear() + (this.getWeekOfYear() == 1 && this.getMonth() > 0 ? +1 : (this.getWeekOfYear() >= 52 && this.getMonth() < 11 ? -1 : 0)))",
			Y: "this.getFullYear()",
			y: "('' + this.getFullYear()).substring(2, 4)",
			a: "(this.getHours() < 12 ? 'am' : 'pm')",
			A: "(this.getHours() < 12 ? 'AM' : 'PM')",
			g: "((this.getHours() % 12) ? this.getHours() % 12 : 12)",
			G: "this.getHours()",
			h: "String.leftPad((this.getHours() % 12) ? this.getHours() % 12 : 12, 2, '0')",
			H: "String.leftPad(this.getHours(), 2, '0')",
			i: "String.leftPad(this.getMinutes(), 2, '0')",
			s: "String.leftPad(this.getSeconds(), 2, '0')",
			u: "String.leftPad(this.getMilliseconds(), 3, '0')",
			O: "this.getGMTOffset()",
			P: "this.getGMTOffset(true)",
			T: "this.getTimezone()",
			Z: "(this.getTimezoneOffset() * -60)",
			c: function () {
				for (var c = "Y-m-dTH:i:sP", code = [], i = 0, l = c.length; i < l; ++i) {
					var e = c.charAt(i);
					code.push(e == "T" ? "'T'" : Date.getFormatCode(e));
				}
				return code.join(" + ");
			},
			U: "Math.round(this.getTime() / 1000)"
		},

		parseDate: function (input, format) {
			var p = Date.parseFunctions;
			if (p[format] == null) {
				Date.createParser(format);
			}
			var func = p[format];
			return Date[func](input);
		},

		getFormatCode: function (character) {
			var f = Date.formatCodes[character];

			if (f) {
				f = Ext.type(f) == 'function' ? f() : f;
				Date.formatCodes[character] = f;
			}

			return f || ("'" + String.escape(character) + "'");
		},

		createNewFormat: function (format) {
			var funcName = "format" + Date.formatFunctions.count++;
			Date.formatFunctions[format] = funcName;
			var code = "Date.prototype." + funcName + " = function(){return ";
			var special = false;
			var ch = '';
			for (var i = 0; i < format.length; ++i) {
				ch = format.charAt(i);
				if (!special && ch == "\\") {
					special = true;
				}
				else if (special) {
					special = false;
					code += "'" + String.escape(ch) + "' + ";
				}
				else {
					code += Date.getFormatCode(ch) + " + ";
				}
			}
			eval(code.substring(0, code.length - 3) + ";}");
		},

		createParser: function (format) {
			var funcName = "parse" + Date.parseFunctions.count++;
			var regexNum = Date.parseRegexes.length;
			var currentGroup = 1;
			Date.parseFunctions[format] = funcName;
			var code = "Date." + funcName + " = function(input){\n"
				+ "var y, m, d, h = 0, i = 0, s = 0, ms = 0, o, z, u, v;\n"
				+ "input = String(input);\n"
				+ "d = new Date();\n"
				+ "y = d.getFullYear();\n"
				+ "m = d.getMonth();\n"
				+ "d = d.getDate();\n"
				+ "var results = input.match(Date.parseRegexes[" + regexNum + "]);\n"
				+ "if (results && results.length > 0) {";
			var regex = "";
			var special = false;
			var ch = '';
			for (var i = 0; i < format.length; ++i) {
				ch = format.charAt(i);
				if (!special && ch == "\\") {
					special = true;
				}
				else if (special) {
					special = false;
					regex += String.escape(ch);
				}
				else {
					var obj = Date.formatCodeToRegex(ch, currentGroup);
					currentGroup += obj.g;
					regex += obj.s;
					if (obj.g && obj.c) {
						code += obj.c;
					}
				}
			}
			code += "if (u){\n"
				+ "v = new Date(u * 1000);\n" + "}else if (y >= 0 && m >= 0 && d > 0 && h >= 0 && i >= 0 && s >= 0 && ms >= 0){\n"
				+ "v = new Date(y, m, d, h, i, s, ms);\n"
				+ "}else if (y >= 0 && m >= 0 && d > 0 && h >= 0 && i >= 0 && s >= 0){\n"
				+ "v = new Date(y, m, d, h, i, s);\n"
				+ "}else if (y >= 0 && m >= 0 && d > 0 && h >= 0 && i >= 0){\n"
				+ "v = new Date(y, m, d, h, i);\n"
				+ "}else if (y >= 0 && m >= 0 && d > 0 && h >= 0){\n"
				+ "v = new Date(y, m, d, h);\n"
				+ "}else if (y >= 0 && m >= 0 && d > 0){\n"
				+ "v = new Date(y, m, d);\n"
				+ "}else if (y >= 0 && m >= 0){\n"
				+ "v = new Date(y, m);\n"
				+ "}else if (y >= 0){\n"
				+ "v = new Date(y);\n"
				+ "}\n}\nreturn (v && (z || o))?"
				+ " (Ext.type(z) == 'number' ? v.add(Date.SECOND, -v.getTimezoneOffset() * 60 - z) :" + " v.add(Date.MINUTE, -v.getTimezoneOffset() + (sn == '+'? -1 : 1) * (hr * 60 + mn))) : v;\n" + "}";
			Date.parseRegexes[regexNum] = new RegExp("^" + regex + "$", "i");
			eval(code);
		},

		parseCodes: {
			d: {
				g: 1,
				c: "d = parseInt(results[{0}], 10);\n",
				s: "(\\d{2})"
			},
			j: {
				g: 1,
				c: "d = parseInt(results[{0}], 10);\n",
				s: "(\\d{1,2})"
			},
			D: function () {
				for (var a = [], i = 0; i < 7; a.push(Date.getShortDayName(i)), ++i) {
				}
				return {
					g: 0,
					c: null,
					s: "(?:" + a.join("|") + ")"
				};
			},
			l: function () {
				return {
					g: 0,
					c: null,
					s: "(?:" + Date.dayNames.join("|") + ")"
				};
			},
			N: {
				g: 0,
				c: null,
				s: "[1-7]"
			},
			S: {
				g: 0,
				c: null,
				s: "(?:st|nd|rd|th)"
			},
			w: {
				g: 0,
				c: null,
				s: "[0-6]"
			},
			z: {
				g: 0,
				c: null,
				s: "(?:\\d{1,3}"
			},
			W: {
				g: 0,
				c: null,
				s: "(?:\\d{2})"
			},
			F: function () {
				return {
					g: 1,
					c: "m = parseInt(Date.getMonthNumber(results[{0}]), 10);\n",
					s: "(" + Date.monthNames.join("|") + ")"
				};
			},
			M: function () {
				for (var a = [], i = 0; i < 12; a.push(Date.getShortMonthName(i)), ++i) {
				}
				return Ext.applyIf({
					s: "(" + a.join("|") + ")"
				}, $f("F"));
			},
			m: {
				g: 1,
				c: "m = parseInt(results[{0}], 10) - 1;\n",
				s: "(\\d{2})"
			},
			n: {
				g: 1,
				c: "m = parseInt(results[{0}], 10) - 1;\n",
				s: "(\\d{1,2})"
			},
			t: {
				g: 0,
				c: null,
				s: "(?:\\d{2})"
			},
			L: {
				g: 0,
				c: null,
				s: "(?:1|0)"
			},
			o: function () {
				return $f("Y");
			},
			Y: {
				g: 1,
				c: "y = parseInt(results[{0}], 10);\n",
				s: "(\\d{4})"
			},
			y: {
				g: 1,
				c: "var ty = parseInt(results[{0}], 10);\n"
			+ "y = ty > Date.y2kYear ? 1900 + ty : 2000 + ty;\n", s: "(\\d{1,2})"
			},
			a: {
				g: 1,
				c: "if (results[{0}] == 'am') {\n"
			+ "if (h == 12) { h = 0; }\n"
			+ "} else { if (h < 12) { h += 12; }}",
				s: "(am|pm)"
			},
			A: {
				g: 1,
				c: "if (results[{0}] == 'AM') {\n"
			+ "if (h == 12) { h = 0; }\n"
			+ "} else { if (h < 12) { h += 12; }}",
				s: "(AM|PM)"
			},
			g: function () {
				return $f("G");
			},
			G: {
				g: 1,
				c: "h = parseInt(results[{0}], 10);\n",
				s: "(\\d{1,2})"
			},
			h: function () {
				return $f("H");
			},
			H: {
				g: 1,
				c: "h = parseInt(results[{0}], 10);\n",
				s: "(\\d{2})"
			},
			i: {
				g: 1,
				c: "i = parseInt(results[{0}], 10);\n",
				s: "(\\d{2})"
			},
			s: {
				g: 1,
				c: "s = parseInt(results[{0}], 10);\n",
				s: "(\\d{2})"
			},
			u: {
				g: 1,
				c: "ms = results[{0}]; ms = parseInt(ms, 10)/Math.pow(10, ms.length - 3);\n",
				s: "(\\d+)"
			},
			O: {
				g: 1,
				c: [
			"o = results[{0}];",
			"var sn = o.substring(0,1);", "var hr = o.substring(1,3)*1 + Math.floor(o.substring(3,5) / 60);", "var mn = o.substring(3,5) % 60;", "o = ((-12 <= (hr*60 + mn)/60) && ((hr*60 + mn)/60 <= 14))? (sn + String.leftPad(hr, 2, '0') + String.leftPad(mn, 2, '0')) : null;\n"].join("\n"),
				s: "([+\-]\\d{4})"
			},
			P: {
				g: 1,
				c: [
			"o = results[{0}];",
			"var sn = o.substring(0,1);", "var hr = o.substring(1,3)*1 + Math.floor(o.substring(4,6) / 60);", "var mn = o.substring(4,6) % 60;", "o = ((-12 <= (hr*60 + mn)/60) && ((hr*60 + mn)/60 <= 14))? (sn + String.leftPad(hr, 2, '0') + String.leftPad(mn, 2, '0')) : null;\n"].join("\n"),
				s: "([+\-]\\d{2}:\\d{2})"
			},
			T: {
				g: 0,
				c: null,
				s: "[A-Z]{1,4}"
			},
			Z: {
				g: 1,
				c: "z = results[{0}] * 1;\n" + "z = (-43200 <= z && z <= 50400)? z : null;\n",
				s: "([+\-]?\\d{1,5})"
			},
			c: function () {
				var calc = [];
				var arr = [
			$f("Y", 1), $f("m", 2), $f("d", 3), $f("h", 4), $f("i", 5), $f("s", 6), { c: "ms = (results[7] || '.0').substring(1); ms = parseInt(ms, 10)/Math.pow(10, ms.length - 3);\n" }, { c: "if(results[9] == 'Z'){\no = 0;\n}else{\n" + $f("P", 9).c + "\n}"}];
				for (var i = 0, l = arr.length; i < l; ++i) {
					calc.push(arr[i].c);
				}

				return {
					g: 1,
					c: calc.join(""),
					s: arr[0].s + "-" + arr[1].s + "-" + arr[2].s + "T" + arr[3].s + ":" + arr[4].s + ":" + arr[5].s
				  + "((\.|,)\\d+)?" + "(" + $f("P", null).s + "|Z)"
				}
			},
			U: {
				g: 1,
				c: "u = parseInt(results[{0}], 10);\n",
				s: "(-?\\d+)"
			}
		}
	});

} ());

Ext.override(Date, {
	dateFormat: function (format) {
		if (Date.formatFunctions[format] == null) {
			Date.createNewFormat(format);
		}
		var func = Date.formatFunctions[format];
		return this[func]();
	},

	getTimezone: function () {
		return this.toString().replace(/^.* (?:\((.*)\)|([A-Z]{1,4})(?:[\-+][0-9]{4})?(?: -?\d+)?)$/, "$1$2").replace(/[^A-Z]/g, "");
	},

	getGMTOffset: function (colon) {
		return (this.getTimezoneOffset() > 0 ? "-" : "+")
		+ String.leftPad(Math.abs(Math.floor(this.getTimezoneOffset() / 60)), 2, "0")
		+ (colon ? ":" : "")
		+ String.leftPad(Math.abs(this.getTimezoneOffset() % 60), 2, "0");
	},

	getDayOfYear: function () {
		var num = 0;
		Date.daysInMonth[1] = this.isLeapYear() ? 29 : 28;
		for (var i = 0; i < this.getMonth(); ++i) {
			num += Date.daysInMonth[i];
		}
		return num + this.getDate() - 1;
	},

	getWeekOfYear: function () {
		var ms1d = 864e5; var ms7d = 7 * ms1d; var DC3 = Date.UTC(this.getFullYear(), this.getMonth(), this.getDate() + 3) / ms1d; var AWN = Math.floor(DC3 / 7); var Wyr = new Date(AWN * ms7d).getUTCFullYear();
		return AWN - Math.floor(Date.UTC(Wyr, 0, 7) / ms7d) + 1;
	},

	isLeapYear: function () {
		var year = this.getFullYear();
		return !!((year & 3) == 0 && (year % 100 || (year % 400 == 0 && year)));
	},

	getFirstDayOfMonth: function () {
		var day = (this.getDay() - (this.getDate() - 1)) % 7;
		return (day < 0) ? (day + 7) : day;
	},

	getLastDayOfMonth: function () {
		var day = (this.getDay() + (Date.daysInMonth[this.getMonth()] - this.getDate())) % 7;
		return (day < 0) ? (day + 7) : day;
	},

	getFirstDateOfMonth: function () {
		return new Date(this.getFullYear(), this.getMonth(), 1);
	},

	getLastDateOfMonth: function () {
		return new Date(this.getFullYear(), this.getMonth(), this.getDaysInMonth());
	},

	getDaysInMonth: function () {
		Date.daysInMonth[1] = this.isLeapYear() ? 29 : 28;
		return Date.daysInMonth[this.getMonth()];
	},

	getSuffix: function () {
		switch (this.getDate()) {
			case 1:
			case 21:
			case 31:
				return "st";
			case 2:
			case 22:
				return "nd";
			case 3:
			case 23:
				return "rd";
			default:
				return "th";
		}
	},

	clone: function () {
		return new Date(this.getTime());
	},

	clearTime: function (clone) {
		if (clone) {
			return this.clone().clearTime();
		}
		this.setHours(0);
		this.setMinutes(0);
		this.setSeconds(0);
		this.setMilliseconds(0);
		return this;
	},

	add: function (interval, value) {
		var d = this.clone();
		if (!interval || value === 0) return d;

		switch (interval.toLowerCase()) {
			case Date.MILLI:
				d.setMilliseconds(this.getMilliseconds() + value);
				break;
			case Date.SECOND:
				d.setSeconds(this.getSeconds() + value);
				break;
			case Date.MINUTE:
				d.setMinutes(this.getMinutes() + value);
				break;
			case Date.HOUR:
				d.setHours(this.getHours() + value);
				break;
			case Date.DAY:
				d.setDate(this.getDate() + value);
				break;
			case Date.MONTH:
				var day = this.getDate();
				if (day > 28) {
					day = Math.min(day, this.getFirstDateOfMonth().add('mo', value).getLastDateOfMonth().getDate());
				}
				d.setDate(day);
				d.setMonth(this.getMonth() + value);
				break;
			case Date.YEAR:
				d.setFullYear(this.getFullYear() + value);
				break;
		}
		return d;
	},

	between: function (start, end) {
		var t = this.getTime();
		return start.getTime() <= t && t <= end.getTime();
	}
});

Date.prototype.format = Date.prototype.dateFormat;

if (Ext.isSafari) {
	Date.brokenSetMonth = Date.prototype.setMonth;
	Date.prototype.setMonth = function (num) {
		if (num <= -1) {
			var n = Math.ceil(-num);
			var back_year = Math.ceil(n / 12);
			var month = (n % 12) ? 12 - n % 12 : 0;
			this.setFullYear(this.getFullYear() - back_year);
			return Date.brokenSetMonth.call(this, month);
		} else {
			return Date.brokenSetMonth.apply(this, arguments);
		}
	};
}

Ext.util.DelayedTask = function (fn, scope, args) {
	var id = null, d, t;

	var call = function () {
		var now = new Date().getTime();
		if (now - t >= d) {
			clearInterval(id);
			id = null;
			fn.apply(scope, args || []);
		}
	};

	this.delay = function (delay, newFn, newScope, newArgs) {
		if (id && delay != d) {
			this.cancel();
		}
		d = delay;
		t = new Date().getTime();
		fn = newFn || fn;
		scope = newScope || scope;
		args = newArgs || args;
		if (!id) {
			id = setInterval(call, d);
		}
	};

	this.cancel = function () {
		if (id) {
			clearInterval(id);
			id = null;
		}
	};
};

Ext.util.TaskRunner = function (interval) {
	interval = interval || 10;
	var tasks = [], removeQueue = [];
	var id = 0;
	var running = false;

	var stopThread = function () {
		running = false;
		clearInterval(id);
		id = 0;
	};

	var startThread = function () {
		if (!running) {
			running = true;
			id = setInterval(runTasks, interval);
		}
	};

	var removeTask = function (t) {
		removeQueue.push(t);
		if (t.onStop) {
			t.onStop.apply(t.scope || t);
		}
	};

	var runTasks = function () {
		if (removeQueue.length > 0) {
			for (var i = 0, len = removeQueue.length; i < len; i++) {
				tasks.remove(removeQueue[i]);
			}
			removeQueue = [];
			if (tasks.length < 1) {
				stopThread();
				return;
			}
		}
		var now = new Date().getTime();
		for (var i = 0, len = tasks.length; i < len; ++i) {
			var t = tasks[i];
			var itime = now - t.taskRunTime;
			if (t.interval <= itime) {
				var rt = t.run.apply(t.scope || t, t.args || [++t.taskRunCount]);
				t.taskRunTime = now;
				if (rt === false || t.taskRunCount === t.repeat) {
					removeTask(t);
					return;
				}
			}
			if (t.duration && t.duration <= (now - t.taskStartTime)) {
				removeTask(t);
			}
		}
	};

	this.start = function (task) {
		tasks.push(task);
		task.taskStartTime = new Date().getTime();
		task.taskRunTime = 0;
		task.taskRunCount = 0;
		startThread();
		return task;
	};

	this.stop = function (task) {
		removeTask(task);
		return task;
	};

	this.stopAll = function () {
		stopThread();
		for (var i = 0, len = tasks.length; i < len; i++) {
			if (tasks[i].onStop) {
				tasks[i].onStop();
			}
		}
		tasks = [];
		removeQueue = [];
	};
};

Ext.TaskMgr = new Ext.util.TaskRunner();

Ext.util.MixedCollection = function (allowFunctions, keyFn) {
	this.items = [];
	this.map = {};
	this.keys = [];
	this.length = 0;
	this.addEvents(
			"clear",
			"add",
			"replace",
			"remove",
			"sort"
		);
	this.allowFunctions = allowFunctions === true;
	if (keyFn) {
		this.getKey = keyFn;
	}
	Ext.util.MixedCollection.superclass.constructor.call(this);
};

Ext.extend(Ext.util.MixedCollection, Ext.util.Observable, {
	allowFunctions: false,

	add: function (key, o) {
		if (arguments.length == 1) {
			o = arguments[0];
			key = this.getKey(o);
		}
		if (typeof key == "undefined" || key === null) {
			this.length++;
			this.items.push(o);
			this.keys.push(null);
		} else {
			var old = this.map[key];
			if (old) {
				return this.replace(key, o);
			}
			this.length++;
			this.items.push(o);
			this.map[key] = o;
			this.keys.push(key);
		}
		this.fireEvent("add", this.length - 1, o, key);
		return o;
	},

	getKey: function (o) {
		return o.id;
	},

	replace: function (key, o) {
		if (arguments.length == 1) {
			o = arguments[0];
			key = this.getKey(o);
		}
		var old = this.item(key);
		if (typeof key == "undefined" || key === null || typeof old == "undefined") {
			return this.add(key, o);
		}
		var index = this.indexOfKey(key);
		this.items[index] = o;
		this.map[key] = o;
		this.fireEvent("replace", key, old, o);
		return o;
	},

	addAll: function (objs) {
		if (arguments.length > 1 || Ext.isArray(objs)) {
			var args = arguments.length > 1 ? arguments : objs;
			for (var i = 0, len = args.length; i < len; i++) {
				this.add(args[i]);
			}
		} else {
			for (var key in objs) {
				if (this.allowFunctions || typeof objs[key] != "function") {
					this.add(key, objs[key]);
				}
			}
		}
	},

	each: function (fn, scope) {
		var items = [].concat(this.items); for (var i = 0, len = items.length; i < len; i++) {
			if (fn.call(scope || items[i], items[i], i, len) === false) {
				break;
			}
		}
	},

	eachKey: function (fn, scope) {
		for (var i = 0, len = this.keys.length; i < len; i++) {
			fn.call(scope || window, this.keys[i], this.items[i], i, len);
		}
	},

	find: function (fn, scope) {
		for (var i = 0, len = this.items.length; i < len; i++) {
			if (fn.call(scope || window, this.items[i], this.keys[i])) {
				return this.items[i];
			}
		}
		return null;
	},

	insert: function (index, key, o) {
		if (arguments.length == 2) {
			o = arguments[1];
			key = this.getKey(o);
		}
		if (index >= this.length) {
			return this.add(key, o);
		}
		this.length++;
		this.items.splice(index, 0, o);
		if (typeof key != "undefined" && key != null) {
			this.map[key] = o;
		}
		this.keys.splice(index, 0, key);
		this.fireEvent("add", index, o, key);
		return o;
	},

	remove: function (o) {
		return this.removeAt(this.indexOf(o));
	},

	removeAt: function (index) {
		if (index < this.length && index >= 0) {
			this.length--;
			var o = this.items[index];
			this.items.splice(index, 1);
			var key = this.keys[index];
			if (typeof key != "undefined") {
				delete this.map[key];
			}
			this.keys.splice(index, 1);
			this.fireEvent("remove", o, key);
			return o;
		}
		return false;
	},

	removeKey: function (key) {
		return this.removeAt(this.indexOfKey(key));
	},

	getCount: function () {
		return this.length;
	},

	indexOf: function (o) {
		return this.items.indexOf(o);
	},

	indexOfKey: function (key) {
		return this.keys.indexOf(key);
	},

	item: function (key) {
		var item = typeof this.map[key] != "undefined" ? this.map[key] : this.items[key];
		return typeof item != 'function' || this.allowFunctions ? item : null;
	},

	itemAt: function (index) {
		return this.items[index];
	},

	key: function (key) {
		return this.map[key];
	},

	contains: function (o) {
		return this.indexOf(o) != -1;
	},

	containsKey: function (key) {
		return typeof this.map[key] != "undefined";
	},

	clear: function () {
		this.length = 0;
		this.items = [];
		this.keys = [];
		this.map = {};
		this.fireEvent("clear");
	},

	first: function () {
		return this.items[0];
	},

	last: function () {
		return this.items[this.length - 1];
	},

	_sort: function (property, dir, fn) {
		var dsc = String(dir).toUpperCase() == "DESC" ? -1 : 1;
		fn = fn || function (a, b) {
			return a - b;
		};
		var c = [], k = this.keys, items = this.items;
		for (var i = 0, len = items.length; i < len; i++) {
			c[c.length] = { key: k[i], value: items[i], index: i };
		}
		c.sort(function (a, b) {
			var v = fn(a[property], b[property]) * dsc;
			if (v == 0) {
				v = (a.index < b.index ? -1 : 1);
			}
			return v;
		});
		for (var i = 0, len = c.length; i < len; i++) {
			items[i] = c[i].value;
			k[i] = c[i].key;
		}
		this.fireEvent("sort", this);
	},

	sort: function (dir, fn) {
		this._sort("value", dir, fn);
	},

	keySort: function (dir, fn) {
		this._sort("key", dir, fn || function (a, b) {
			return String(a).toUpperCase() - String(b).toUpperCase();
		});
	},

	getRange: function (start, end) {
		var items = this.items;
		if (items.length < 1) {
			return [];
		}
		start = start || 0;
		end = Math.min(typeof end == "undefined" ? this.length - 1 : end, this.length - 1);
		var r = [];
		if (start <= end) {
			for (var i = start; i <= end; i++) {
				r[r.length] = items[i];
			}
		} else {
			for (var i = start; i >= end; i--) {
				r[r.length] = items[i];
			}
		}
		return r;
	},

	filter: function (property, value, anyMatch, caseSensitive) {
		if (Ext.isEmpty(value, false)) {
			return this.clone();
		}
		value = this.createValueMatcher(value, anyMatch, caseSensitive);
		return this.filterBy(function (o) {
			return o && value.test(o[property]);
		});
	},

	filterBy: function (fn, scope) {
		var r = new Ext.util.MixedCollection();
		r.getKey = this.getKey;
		var k = this.keys, it = this.items;
		for (var i = 0, len = it.length; i < len; i++) {
			if (fn.call(scope || this, it[i], k[i])) {
				r.add(k[i], it[i]);
			}
		}
		return r;
	},

	findIndex: function (property, value, start, anyMatch, caseSensitive) {
		if (Ext.isEmpty(value, false)) {
			return -1;
		}
		value = this.createValueMatcher(value, anyMatch, caseSensitive);
		return this.findIndexBy(function (o) {
			return o && value.test(o[property]);
		}, null, start);
	},

	findIndexBy: function (fn, scope, start) {
		var k = this.keys, it = this.items;
		for (var i = (start || 0), len = it.length; i < len; i++) {
			if (fn.call(scope || this, it[i], k[i])) {
				return i;
			}
		}
		if (typeof start == 'number' && start > 0) {
			for (var i = 0; i < start; i++) {
				if (fn.call(scope || this, it[i], k[i])) {
					return i;
				}
			}
		}
		return -1;
	},

	createValueMatcher: function (value, anyMatch, caseSensitive) {
		if (!value.exec) {
			value = String(value);
			value = new RegExp((anyMatch === true ? '' : '^') + Ext.escapeRe(value), caseSensitive ? '' : 'i');
		}
		return value;
	},

	deepClone: function () {
		var r = new Ext.util.MixedCollection();
		var k = this.keys, it = this.items, newItem;
		for (var i = 0, len = it.length; i < len; i++) {
			newItem = {};
			Ext.apply(newItem, it[i]);
			r.add(k[i], newItem);
		}
		r.getKey = this.getKey;
		return r;
	},

	clone: function (deep) {
		if (deep === true) {
			return this.deepClone();
		}
		var r = new Ext.util.MixedCollection();
		var k = this.keys, it = this.items;
		for (var i = 0, len = it.length; i < len; i++) {
			r.add(k[i], it[i]);
		}
		r.getKey = this.getKey;
		return r;
	}
});

Ext.util.MixedCollection.prototype.get = Ext.util.MixedCollection.prototype.item;

Ext.util.JSON = new (function () {
	var useHasOwn = !!{}.hasOwnProperty;
	var isNative = function () {
		var useNative = null;
		return function () {
			if (useNative === null) {
				useNative = Ext.USE_NATIVE_JSON && window.JSON && JSON.toString() == '[object JSON]';
			}
			return useNative;
		};
	} ();

	var doEncode = function (o, depth) {
		if (typeof o == "undefined" || o === null) {
			return "null";
		} else if (Ext.isArray(o)) {
			return encodeArray(o, depth);
		} else if (Ext.isDate(o)) {
			return Ext.util.JSON.encodeDate(o);
		} else if (typeof o == "string") {
			return encodeString(o);
		} else if (typeof o == "number") {
			return isFinite(o) ? String(o) : "null";
		} else if (typeof o == "boolean") {
			return String(o);
		} else {
			return Ext.util.JSON.encodeObject(o, depth);
		}
	};

	var doDecode = function (json) {
		return eval("(" + json + ')');
	};

	var pad = function (n) {
		return n < 10 ? "0" + n : n;
	};

	var m = {
		"\b": '\\b',
		"\t": '\\t',
		"\n": '\\n',
		"\f": '\\f',
		"\r": '\\r',
		'"': '\\"',
		"\\": '\\\\'
	};

	var encodeString = function (s) {
		if (/["\\\x00-\x1f]/.test(s)) {
			return '"' + s.replace(/([\x00-\x1f\\"])/g, function (a, b) {
				var c = m[b];
				if (c) {
					return c;
				}
				c = b.charCodeAt();
				return "\\u00" +
				Math.floor(c / 16).toString(16) +
				(c % 16).toString(16);
			}) + '"';
		}
		return '"' + s + '"';
	};

	var encodeArray = function (o, depth) {
		var a = ["["], b, i, l = o.length, v;
		for (i = 0; i < l; i += 1) {
			v = o[i];
			switch (typeof v) {
				case "undefined":
				case "function":
				case "unknown":
					break;
				default:
					if (b) {
						a.push(',');
					}
					a.push(v === null ? "null" : Ext.util.JSON.encode(v, depth));
					b = true;
			}
		}
		a.push("]");
		return a.join("");
	};

	this.encodeString = encodeString;

	this.encodeNamedArray = function (o, depth) {
		var a = ["["], b, i, l = o.length, v;
		for (i in o) {
			v = o[i];
			switch (typeof v) {
				case "undefined":
				case "function":
				case "unknown":
					break;
				default:
					if (b) {
						a.push(',');
					}
					a.push(v === null ? "null" : Ext.util.JSON.encode(v, depth));
					b = true;
			}
		}
		a.push("]");
		return a.join("");
	};

	this.encodeDate = function (o) {
		return '"' + o.getFullYear() + "-" +
			pad(o.getMonth() + 1) + "-" +
			pad(o.getDate()) + "T" +
			pad(o.getHours()) + ":" +
			pad(o.getMinutes()) + ":" +
			pad(o.getSeconds()) + '"';
	};

	this.decodeDate = function (json) {
		var str = Ext.util.JSON.decode(json);
		var format = "Y-m-dTG:i:s";
		var date = Date.parseDate(str, format);
		return date;
	},

		this.encode = function () {
			var ec;
			return function (o, depth) {
				if (!ec) {
					ec = isNative() ? JSON.stringify : doEncode;
				}
				return ec(o, depth);
			};
		} ();

	this.encodeObjectRestrict = function (o, restrictObject, depth) {
		var a = ["{"], b, i, v;
		for (i in o) {
			if (restrictObject[i]) {
				continue;
			}
			if (!useHasOwn || o.hasOwnProperty(i)) {
				v = o[i];
				switch (typeof v) {
					case "undefined":
					case "function":
					case "unknown":
						break;
					default:
						if (b) {
							a.push(',');
						}
						a.push(this.encode(i), ":",
						v === null ? "null" : this.encode(v, depth - 1));
						b = true;
				}
			}
		}
		a.push("}");
		return a.join("");
	};

	this.encodeObject = function (o, depth) {
		if (depth === 0) {
			return '{}';
		}
		return Ext.util.JSON.encodeObjectRestrict(o, {}, depth);
	}

	this.decode = function () {
		var dc;
		return function (json) {
			if (!dc) {
				dc = isNative() ? JSON.parse : doDecode;
			}
			return dc(json);
		};
	} ();

})();

Ext.encode = Ext.util.JSON.encode;

Ext.decode = Ext.util.JSON.decode;

Ext.util.Format = function () {
	var trimRe = /^\s+|\s+$/g;
	return {
		ellipsis: function (value, len) {
			if (value && value.length > len) {
				return value.substr(0, len - 3) + "...";
			}
			return value;
		},

		undef: function (value) {
			return value !== undefined ? value : "";
		},

		defaultValue: function (value, defaultValue) {
			return value !== undefined && value !== '' ? value : defaultValue;
		},

		htmlEncode: function (value) {
			if (!value) {
				return value;
			}
			var encodedValue = String(value);
			encodedValue = encodedValue.replace(/&/g, "&amp;");
			encodedValue = encodedValue.replace(/>/g, "&gt;");
			encodedValue = encodedValue.replace(/</g, "&lt;");
			encodedValue = encodedValue.replace(/"/g, "&quot;");
			encodedValue = encodedValue.replace(/'/g, "&apos;");
			return encodedValue;
		},

		htmlDecode: function (value) {
			if (!value) {
				return value;
			}
			var decodedValue = String(value);
			decodedValue = decodedValue.replace(/&gt;/g, ">");
			decodedValue = decodedValue.replace(/&lt;/g, "<");
			decodedValue = decodedValue.replace(/&quot;/g, '"');
			decodedValue = decodedValue.replace(/&apos;/g, "'");
			decodedValue = decodedValue.replace( /&#(\d{1,3});/g , function(str, p1) {
				return String.fromCharCode(parseInt(p1));
			});
			decodedValue = decodedValue.replace(/&amp;/g, "&");
			return decodedValue;
		},

		trim: function (value) {
			return String(value).replace(trimRe, "");
		},

		substr: function (value, start, length) {
			return String(value).substr(start, length);
		},

		lowercase: function (value) {
			return String(value).toLowerCase();
		},

		uppercase: function (value) {
			return String(value).toUpperCase();
		},

		capitalize: function (value) {
			return !value ? value : value.charAt(0).toUpperCase() + value.substr(1).toLowerCase();
		},

		call: function (value, fn) {
			if (arguments.length > 2) {
				var args = Array.prototype.slice.call(arguments, 2);
				args.unshift(value);
				return eval(fn).apply(window, args);
			} else {
				return eval(fn).call(window, value);
			}
		},

		usMoney: function (v) {
			v = (Math.round((v - 0) * 100)) / 100;
			v = (v == Math.floor(v)) ? v + ".00" : ((v * 10 == Math.floor(v * 10)) ? v + "0" : v);
			v = String(v);
			var ps = v.split('.');
			var whole = ps[0];
			var sub = ps[1] ? '.' + ps[1] : '.00';
			var r = /(\d+)(\d{3})/;
			while (r.test(whole)) {
				whole = whole.replace(r, '$1' + ',' + '$2');
			}
			v = whole + sub;
			if (v.charAt(0) == '-') {
				return '-$' + v.substr(1);
			}
			return "$" + v;
		},

		date: function (v, format) {
			if (!v) {
				return "";
			}
			if (!Ext.isDate(v)) {
				v = new Date(Date.parse(v));
			}
			return v.dateFormat(format || "d.m.Y");
		},

		getDateTimeFormat: function () {
			return this.getDateFormat() + ' ' + this.getTimeFormat();
		},

		getDateFormat: function () {
			if (!this.dateFormatValue) {
				this.dateFormatValue = Terrasoft.CultureInfo.dateFormat;
			}
			return this.dateFormatValue;
		},

		getTimeFormat: function () {
			if (!this.timeFormatValue) {
				this.timeFormatValue = Terrasoft.CultureInfo.timeFormat;
			}
			return this.timeFormatValue;
		},

		dateTimeFormat: function (v) {
			return this.date(v, this.getDateTimeFormat());
		},

		dateFormat: function (v) {
			return this.date(v, this.getDateFormat());
		},

		timeFormat: function (v) {
			return this.date(v, this.getTimeFormat());
		},

		dateRenderer: function (format) {
			return function (v) {
				return Ext.util.Format.date(v, format);
			};
		},

		stripTagsRE: /<\/?[^>]+>/gi,

		stripTags: function (v) {
			return !v ? v : String(v).replace(this.stripTagsRE, "");
		},

		stripScriptsRe: /(?:<script.*?>)((\n|\r|.)*?)(?:<\/script>)/ig,

		stripScripts: function (v) {
			return !v ? v : String(v).replace(this.stripScriptsRe, "");
		},

		fileSize: function (size) {
			if (size < 1024) {
				return size + " bytes";
			} else if (size < 1048576) {
				return (Math.round(((size * 10) / 1024)) / 10) + " KB";
			} else {
				return (Math.round(((size * 10) / 1048576)) / 10) + " MB";
			}
		},

		math: function () {
			var fns = {};
			return function (v, a) {
				if (!fns[a]) {
					fns[a] = new Function('v', 'return v ' + a + ';');
				}
				return fns[a](v);
			}
		} (),

		nl2br: function (v) {
			return v === undefined || v === null ? '' : v.replace(/\n/g, '<br/>');
		}
	};
} ();

Ext.util.Clone = function (obj) {
	if (Ext.isEmpty(obj)) {
		return obj;
	}
	var clone = new obj.constructor();
	for (var property in obj) {
		if (typeof obj[property] == 'object') {
			clone[property] = Ext.util.Clone(obj[property]);
		} else {
			clone[property] = obj[property];
		}
	}
	return clone;
};

Ext.XTemplate = function () {
	Ext.XTemplate.superclass.constructor.apply(this, arguments);
	var s = this.html;

	s = ['<tpl>', s, '</tpl>'].join('');

	var re = /<tpl\b[^>]*>((?:(?=([^<]+))\2|<(?!tpl\b[^>]*>))*?)<\/tpl>/;

	var nameRe = /^<tpl\b[^>]*?for="(.*?)"/;
	var ifRe = /^<tpl\b[^>]*?if="(.*?)"/;
	var execRe = /^<tpl\b[^>]*?exec="(.*?)"/;
	var m, id = 0;
	var tpls = [];

	while (m = s.match(re)) {
		var m2 = m[0].match(nameRe);
		var m3 = m[0].match(ifRe);
		var m4 = m[0].match(execRe);
		var exp = null, fn = null, exec = null;
		var name = m2 && m2[1] ? m2[1] : '';
		if (m3) {
			exp = m3 && m3[1] ? m3[1] : null;
			if (exp) {
				fn = new Function('values', 'parent', 'xindex', 'xcount', 'with(values){ return ' + (Ext.util.Format.htmlDecode(exp)) + '; }');
			}
		}
		if (m4) {
			exp = m4 && m4[1] ? m4[1] : null;
			if (exp) {
				exec = new Function('values', 'parent', 'xindex', 'xcount', 'with(values){ ' + (Ext.util.Format.htmlDecode(exp)) + '; }');
			}
		}
		if (name) {
			switch (name) {
				case '.': name = new Function('values', 'parent', 'with(values){ return values; }'); break;
				case '..': name = new Function('values', 'parent', 'with(values){ return parent; }'); break;
				default: name = new Function('values', 'parent', 'with(values){ return ' + name + '; }');
			}
		}
		tpls.push({
			id: id,
			target: name,
			exec: exec,
			test: fn,
			body: m[1] || ''
		});
		s = s.replace(m[0], '{xtpl' + id + '}');
		++id;
	}
	for (var i = tpls.length - 1; i >= 0; --i) {
		this.compileTpl(tpls[i]);
	}
	this.master = tpls[tpls.length - 1];
	this.tpls = tpls;
};

Ext.extend(Ext.XTemplate, Ext.Template, {
	re: /\{([\w-\.\#]+)(?:\:([\w\.]*)(?:\((.*?)?\))?)?(\s?[\+\-\*\\]\s?[\d\.\+\-\*\\\(\)]+)?\}/g,
	codeRe: /\{\[((?:\\\]|.|\n)*?)\]\}/g,

	applySubTemplate: function (id, values, parent, xindex, xcount) {
		var t = this.tpls[id];
		if (t.test && !t.test.call(this, values, parent, xindex, xcount)) {
			return '';
		}
		if (t.exec && t.exec.call(this, values, parent, xindex, xcount)) {
			return '';
		}
		var vs = t.target ? t.target.call(this, values, parent) : values;
		parent = t.target ? values : parent;
		if (t.target && Ext.isArray(vs)) {
			var buf = [];
			for (var i = 0, len = vs.length; i < len; i++) {
				buf[buf.length] = t.compiled.call(this, vs[i], parent, i + 1, len);
			}
			return buf.join('');
		}
		return t.compiled.call(this, vs, parent, xindex, xcount);
	},

	compileTpl: function (tpl) {
		this.compileTpl["tpl"] = tpl;
		var useF = this.disableFormats !== true;
		var sep = Ext.isGecko ? "+" : ",";
		var fn = function (m, name, format, args, math) {
			if (name.substr(0, 4) == 'xtpl') {
				return "'" + sep + 'this.applySubTemplate(' + name.substr(4) + ', values, parent, xindex, xcount)' + sep + "'";
			}
			var v;
			if (name === '.') {
				v = 'values';
			} else if (name === '#') {
				v = 'xindex';
			} else if (name.indexOf('.') != -1) {
				v = name;
			} else {
				v = "values['" + name + "']";
			}
			if (math) {
				v = '(' + v + math + ')';
			}
			if (format && useF) {
				args = args ? ',' + args : "";
				if (format.substr(0, 5) != "this.") {
					format = "Ext.util.Format." + format + '(';
				} else {
					format = 'this.call("' + format.substr(5) + '", ';
					args = ", values";
				}
			} else {
				args = ''; format = "(" + v + " === undefined ? '' : ";
			}
			return "'" + sep + format + v + args + ")" + sep + "'";
		};

		var codeFn = function (m, code) {
			return "'" + sep + '(' + code + ')' + sep + "'";
		};

		var body;
		if (Ext.isGecko) {
			body = "this.compileTpl.tpl.compiled = function(values, parent, xindex, xcount){ return '" +
				tpl.body.replace(/(\r\n|\n)/g, '\\n').replace(/'/g, "\\'").replace(this.re, fn).replace(this.codeRe, codeFn) +
				"';};";
		} else {
			body = ["this.compileTpl.tpl.compiled = function(values, parent, xindex, xcount){ return ['"];
			body.push(tpl.body.replace(/(\r\n|\n)/g, '\\n').replace(/'/g, "\\'").replace(this.re, fn).replace(this.codeRe, codeFn));
			body.push("'].join('');};delete this.compileTpl.tpl;");
			body = body.join('');
		}
		eval(body);
		return this;
	},

	applyTemplate: function (values) {
		return this.master.compiled.call(this, values, {}, 1, 1);
	},

	compile: function () { return this; }
});

Ext.XTemplate.prototype.apply = Ext.XTemplate.prototype.applyTemplate;

Ext.XTemplate.from = function (el) {
	el = Ext.getDom(el);
	return new Ext.XTemplate(el.value || el.innerHTML);
};

Ext.util.CSS = function () {
	var rules = null;
	var doc = document;

	var camelRe = /(-[a-z])/gi;
	var camelFn = function (m, a) { return a.charAt(1).toUpperCase(); };

	return {
		createStyleSheet: function (cssText, id) {
			var ss;
			var head = doc.getElementsByTagName("head")[0];
			var rules = doc.createElement("style");
			rules.setAttribute("type", "text/css");
			if (id) {
				rules.setAttribute("id", id);
			}
			if (Ext.isIE) {
				head.appendChild(rules);
				ss = rules.styleSheet;
				ss.cssText = cssText;
			} else {
				try {
					rules.appendChild(doc.createTextNode(cssText));
				} catch (e) {
					rules.cssText = cssText;
				}
				head.appendChild(rules);
				ss = rules.styleSheet ? rules.styleSheet : (rules.sheet || doc.styleSheets[doc.styleSheets.length - 1]);
			}
			this.cacheStyleSheet(ss);
			return ss;
		},

		removeStyleSheet: function (id) {
			var existing = doc.getElementById(id);
			if (existing) {
				existing.parentNode.removeChild(existing);
			}
		},

		swapStyleSheet: function (id, url) {
			this.removeStyleSheet(id);
			var ss = doc.createElement("link");
			ss.setAttribute("rel", "stylesheet");
			ss.setAttribute("type", "text/css");
			ss.setAttribute("id", id);
			ss.setAttribute("href", url);
			doc.getElementsByTagName("head")[0].appendChild(ss);
		},

		refreshCache: function () {
			return this.getRules(true);
		},

		cacheStyleSheet: function (ss) {
			if (!rules) {
				rules = {};
			}
			try {
				var ssRules = ss.cssRules || ss.rules;
				for (var j = ssRules.length - 1; j >= 0; --j) {
					rules[ssRules[j].selectorText] = ssRules[j];
				}
			} catch (e) { }
		},

		getRules: function (refreshCache) {
			if (rules == null || refreshCache) {
				rules = {};
				var ds = doc.styleSheets;
				for (var i = 0, len = ds.length; i < len; i++) {
					try {
						this.cacheStyleSheet(ds[i]);
					} catch (e) { }
				}
			}
			return rules;
		},

		getRule: function (selector, refreshCache) {
			var rs = this.getRules(refreshCache);
			if (!Ext.isArray(selector)) {
				return rs[selector];
			}
			for (var i = 0; i < selector.length; i++) {
				if (rs[selector[i]]) {
					return rs[selector[i]];
				}
			}
			return null;
		},

		updateRule: function (selector, property, value) {
			if (!Ext.isArray(selector)) {
				var rule = this.getRule(selector);
				if (rule) {
					rule.style[property.replace(camelRe, camelFn)] = value;
					return true;
				}
			} else {
				for (var i = 0; i < selector.length; i++) {
					if (this.updateRule(selector[i], property, value)) {
						return true;
					}
				}
			}
			return false;
		}
	};
} ();

Ext.util.ClickRepeater = function (el, config) {
	this.el = Ext.get(el);
	this.el.unselectable();
	Ext.apply(this, config);
	this.addEvents(
		"mousedown",
		"click",
		"mouseup"
);

	this.el.on("mousedown", this.handleMouseDown, this);
	if (this.preventDefault || this.stopDefault) {
		this.el.on("click", function (e) {
			if (this.preventDefault) {
				e.preventDefault();
			}
			if (this.stopDefault) {
				e.stopEvent();
			}
		}, this);
	}

	if (this.handler) {
		this.on("click", this.handler, this.scope || this);
	}

	Ext.util.ClickRepeater.superclass.constructor.call(this);
};

Ext.extend(Ext.util.ClickRepeater, Ext.util.Observable, {
	interval: 20,
	delay: 250,
	preventDefault: true,
	stopDefault: false,
	timer: 0,

	handleMouseDown: function () {
		clearTimeout(this.timer);
		this.el.blur();
		if (this.pressClass) {
			this.el.addClass(this.pressClass);
		}
		this.mousedownTime = new Date();

		Ext.getDoc().on("mouseup", this.handleMouseUp, this);
		this.el.on("mouseout", this.handleMouseOut, this);

		this.fireEvent("mousedown", this);
		this.fireEvent("click", this);

		if (this.accelerate) {
			this.delay = 400;
		}
		this.timer = this.click.defer(this.delay || this.interval, this);
	},

	click: function () {
		this.fireEvent("click", this);
		this.timer = this.click.defer(this.accelerate ?
		this.easeOutExpo(this.mousedownTime.getElapsed(),
			400,
			-390,
			12000) :
		this.interval, this);
	},

	easeOutExpo: function (t, b, c, d) {
		return (t == d) ? b + c : c * (-Math.pow(2, -10 * t / d) + 1) + b;
	},

	handleMouseOut: function () {
		clearTimeout(this.timer);
		if (this.pressClass) {
			this.el.removeClass(this.pressClass);
		}
		this.el.on("mouseover", this.handleMouseReturn, this);
	},

	handleMouseReturn: function () {
		this.el.un("mouseover", this.handleMouseReturn, this);
		if (this.pressClass) {
			this.el.addClass(this.pressClass);
		}
		this.click();
	},

	handleMouseUp: function () {
		clearTimeout(this.timer);
		this.el.un("mouseover", this.handleMouseReturn, this);
		this.el.un("mouseout", this.handleMouseOut, this);
		Ext.getDoc().un("mouseup", this.handleMouseUp, this);
		this.el.removeClass(this.pressClass);
		this.fireEvent("mouseup", this);
	}
});

Ext.KeyNav = function (el, config) {
	this.el = Ext.get(el);
	Ext.apply(this, config);
	if (!this.disabled) {
		this.disabled = true;
		this.enable();
	}
};

Ext.KeyNav.prototype = {
	disabled: false,
	defaultEventAction: "stopEvent",
	forceKeyDown: false,

	relay: function (e) {
		var k = e.getKey();
		var h = this.keyToHandler[k];
		if (h && this[h]) {
			if (this.doRelay(e, this[h], h) !== true) {
				e[this.defaultEventAction]();
			}
		}
	},

	doRelay: function (e, h, hname) {
		return h.call(this.scope || this, e, hname);
	},

	enter: false,
	left: false,
	right: false,
	up: false,
	down: false,
	tab: false,
	esc: false,
	pageUp: false,
	pageDown: false,
	del: false,
	home: false,
	end: false,

	keyToHandler: {
		37: "left",
		39: "right",
		38: "up",
		40: "down",
		33: "pageUp",
		34: "pageDown",
		46: "del",
		36: "home",
		35: "end",
		13: "enter",
		27: "esc",
		9: "tab",
		113: "f2",
		45: "insert",
		67: "c",
		81: "q",
		87: "w"
	},

	stopKeyUp: function (e) {
		var k = e.getKey();
		if (k >= 37 && k <= 40) {
			e.stopEvent();
		}
	},

	destroy: function () {
		this.disable();
	},


	enable: function () {
		if (this.disabled) {
			if (Ext.isSafari2) {
				this.el.on('keyup', this.stopKeyUp, this);
			}
			this.el.on(this.isKeydown() ? 'keydown' : 'keypress', this.relay, this);
			this.disabled = false;
		}
	},

	disable: function () {
		if (!this.disabled) {
			if (Ext.isSafari2) {
				this.el.un('keyup', this.stopKeyUp, this);
			}
			this.el.un(this.isKeydown() ? 'keydown' : 'keypress', this.relay, this);
			this.disabled = true;
		}
	},

	setDisabled: function (disabled) {
		this[disabled ? "disable" : "enable"]();
	},
	isKeydown: function () {
		return this.forceKeyDown || Ext.EventManager.useKeydown;
	}
};

Ext.KeyMap = function (el, config, eventName) {
	this.el = Ext.get(el);
	this.eventName = eventName || "keydown";
	this.bindings = [];
	if (config) {
		this.addBinding(config);
	}
	this.enable();
};

Ext.KeyMap.prototype = {
	stopEvent: false,

	addBinding: function (config) {
		if (Ext.isArray(config)) {
			for (var i = 0, len = config.length; i < len; i++) {
				this.addBinding(config[i]);
			}
			return;
		}
		var keyCode = config.key,
		shift = config.shift,
		ctrl = config.ctrl,
		alt = config.alt,
		fn = config.fn || config.handler,
		scope = config.scope;

		if (config.stopEvent) {
			this.stopEvent = config.stopEvent;
		}

		if (typeof keyCode == "string") {
			var ks = [];
			var keyString = keyCode.toUpperCase();
			for (var j = 0, len = keyString.length; j < len; j++) {
				ks.push(keyString.charCodeAt(j));
			}
			keyCode = ks;
		}
		var keyArray = Ext.isArray(keyCode);

		var handler = function (e) {
			if ((!shift || e.shiftKey) && (!ctrl || e.ctrlKey) && (!alt || e.altKey)) {
				var k = e.getKey();
				if (keyArray) {
					for (var i = 0, len = keyCode.length; i < len; i++) {
						if (keyCode[i] == k) {
							if (this.stopEvent) {
								e.stopEvent();
							}
							fn.call(scope || window, k, e);
							return;
						}
					}
				} else {
					if (k == keyCode) {
						if (this.stopEvent) {
							e.stopEvent();
						}
						fn.call(scope || window, k, e);
					}
				}
			}
		};
		this.bindings.push(handler);
	},

	on: function (key, fn, scope) {
		var keyCode, shift, ctrl, alt;
		if (typeof key == "object" && !Ext.isArray(key)) {
			keyCode = key.key;
			shift = key.shift;
			ctrl = key.ctrl;
			alt = key.alt;
		} else {
			keyCode = key;
		}
		this.addBinding({
			key: keyCode,
			shift: shift,
			ctrl: ctrl,
			alt: alt,
			fn: fn,
			scope: scope
		})
	},

	handleKeyDown: function (e) {
		if (this.enabled) {
			var b = this.bindings;
			for (var i = 0, len = b.length; i < len; i++) {
				b[i].call(this, e);
			}
		}
	},

	isEnabled: function () {
		return this.enabled;
	},

	enable: function () {
		if (!this.enabled) {
			this.el.on(this.eventName, this.handleKeyDown, this);
			this.enabled = true;
		}
	},

	disable: function () {
		if (this.enabled) {
			this.el.removeListener(this.eventName, this.handleKeyDown, this);
			this.enabled = false;
		}
	}
};

Ext.util.TextMetrics = function () {
	var shared;
	return {
		measure: function (el, text, fixedWidth) {
			if (!shared) {
				shared = Ext.util.TextMetrics.Instance(el, fixedWidth);
			}
			shared.bind(el);
			shared.setFixedWidth(fixedWidth || 'auto');
			return shared.getSize(text);
		},

		createInstance: function (el, fixedWidth) {
			return Ext.util.TextMetrics.Instance(el, fixedWidth);
		}
	};
} ();

Ext.util.TextMetrics.Instance = function (bindTo, fixedWidth) {
	var ml = new Ext.Element(document.createElement('div'));
	document.body.appendChild(ml.dom);
	ml.position('absolute');
	ml.setLeftTop(-1000, -1000);
	ml.hide();

	if (fixedWidth) {
		ml.setWidth(fixedWidth);
	}

	var instance = {
		getSize: function (text) {
			ml.update(text);
			var s = ml.getSize();
			ml.update('');
			return s;
		},

		bind: function (el) {
			ml.setStyle(
			Ext.fly(el).getStyles('font-size', 'font-style', 'font-weight', 'font-family', 'line-height', 'text-transform', 'letter-spacing'));
		},

		setFixedWidth: function (width) {
			ml.setWidth(width);
		},

		getWidth: function (text) {
			ml.dom.style.width = 'auto';
			return this.getSize(text).width;
		},

		getHeight: function (text) {
			return this.getSize(text).height;
		}
	};
	instance.bind(bindTo);
	return instance;
};

Ext.Element.measureText = Ext.util.TextMetrics.measure;

(function () {

	var Event = Ext.EventManager;
	var Dom = Ext.lib.Dom;

	Ext.dd.DragDrop = function (id, sGroup, config) {
		if (id) {
			this.init(id, sGroup, config);
		}
	};

	Ext.dd.DragDrop.prototype = {
		id: null,
		config: null,
		dragElId: null,
		handleElId: null,
		invalidHandleTypes: null,
		invalidHandleIds: null,
		invalidHandleClasses: null,
		startPageX: 0,
		startPageY: 0,
		groups: null,
		locked: false,

		lock: function () { this.locked = true; },

		unlock: function () { this.locked = false; },

		isTarget: true,

		padding: null,

		_domRef: null,

		__ygDragDrop: true,

		constrainX: false,

		constrainY: false,

		minX: 0,

		maxX: 0,

		minY: 0,

		maxY: 0,

		maintainOffset: false,

		xTicks: null,

		yTicks: null,

		primaryButtonOnly: true,

		available: false,

		hasOuterHandles: false,
		outerHandlesCount: 0,
		b4StartDrag: function (x, y) { },
		startDrag: function (x, y) { },
		b4Drag: function (e) { },

		onDrag: function (e) { },

		onDragEnter: function (e, id) { },

		b4DragOver: function (e) { },

		onDragOver: function (e, id) { },

		b4DragOut: function (e) { },

		onDragOut: function (e, id) { },

		b4DragDrop: function (e) { },

		onDragDrop: function (e, id) { },

		onInvalidDrop: function (e) { },

		b4EndDrag: function (e) { },

		endDrag: function (e) { },

		b4MouseDown: function (e) { },

		onMouseDown: function (e) { },

		onMouseUp: function (e) { },

		onAvailable: function () {
		},

		defaultPadding: { left: 0, right: 0, top: 0, bottom: 0 },

		constrainTo: function (constrainTo, pad, inContent) {
			if (typeof pad == "number") {
				pad = { left: pad, right: pad, top: pad, bottom: pad };
			}
			pad = pad || this.defaultPadding;
			var b = Ext.get(this.getEl()).getBox();
			var ce = Ext.get(constrainTo);
			var s = ce.getScroll();
			var c, cd = ce.dom;
			if (cd == document.body) {
				c = { x: s.left, y: s.top, width: Ext.lib.Dom.getViewWidth(), height: Ext.lib.Dom.getViewHeight() };
			} else {
				var xy = ce.getXY();
				c = { x: xy[0] + s.left, y: xy[1] + s.top, width: cd.clientWidth, height: cd.clientHeight };
			}

			var topSpace = b.y - c.y;
			var leftSpace = b.x - c.x;

			this.resetConstraints();
			this.setXConstraint(leftSpace - (pad.left || 0),
                c.width - leftSpace - b.width - (pad.right || 0),
				this.xTickSize
        );
			this.setYConstraint(topSpace - (pad.top || 0),
                c.height - topSpace - b.height - (pad.bottom || 0),
				this.yTickSize
        );
		},

		getEl: function () {
			if (!this._domRef) {
				this._domRef = Ext.getDom(this.id);
			}

			return this._domRef;
		},

		getDragEl: function () {
			return Ext.getDom(this.dragElId);
		},

		init: function (id, sGroup, config) {
			this.initTarget(id, sGroup, config);
			Event.on(this.id, "mousedown", this.handleMouseDown, this);
		},

		initTarget: function (id, sGroup, config) {
			this.config = config || {};
			this.DDM = Ext.dd.DDM;
			var isGroupsCfg = Boolean(this.groups);
			this.groups = this.groups || {};

			if (typeof id !== "string") {
				id = Ext.id(id);
			}
			this.id = id;
			if (sGroup || !isGroupsCfg) {
				this.groups[(sGroup) ? sGroup : "default"] = true;
			}
			for (var sGroup in this.groups) {
				if ("string" != typeof sGroup) {
					continue;
				}
				this.DDM.regDragDrop(this, sGroup);
			}
			this.handleElId = id;
			this.setDragElId(id);
			this.invalidHandleTypes = { A: "A" };
			this.invalidHandleIds = {};
			this.invalidHandleClasses = [];
			this.applyConfig();
			this.handleOnAvailable();
		},

		applyConfig: function () {
			this.padding = this.config.padding || [0, 0, 0, 0];
			this.isTarget = (this.config.isTarget !== false);
			this.maintainOffset = (this.config.maintainOffset);
			this.primaryButtonOnly = (this.config.primaryButtonOnly !== false);

		},

		handleOnAvailable: function () {
			this.available = true;
			this.resetConstraints();
			this.onAvailable();
		},

		setPadding: function (iTop, iRight, iBot, iLeft) {
			if (!iRight && 0 !== iRight) {
				this.padding = [iTop, iTop, iTop, iTop];
			} else if (!iBot && 0 !== iBot) {
				this.padding = [iTop, iRight, iTop, iRight];
			} else {
				this.padding = [iTop, iRight, iBot, iLeft];
			}
		},

		setInitPosition: function (diffX, diffY) {
			var el = this.getEl();

			if (!this.DDM.verifyEl(el)) {
				return;
			}
			var dx = diffX || 0;
			var dy = diffY || 0;
			var p = Dom.getXY(el);

			this.initPageX = p[0] - dx;
			this.initPageY = p[1] - dy;

			this.lastPageX = p[0];
			this.lastPageY = p[1];

			this.setStartPosition(p);
		},

		setStartPosition: function (pos) {
			var p = pos || Dom.getXY(this.getEl());
			this.deltaSetXY = null;

			this.startPageX = p[0];
			this.startPageY = p[1];
		},

		addToGroup: function (sGroup) {
			this.groups[sGroup] = true;
			this.DDM.regDragDrop(this, sGroup);
		},

		removeFromGroup: function (sGroup) {
			if (this.groups[sGroup]) {
				delete this.groups[sGroup];
			}

			this.DDM.removeDDFromGroup(this, sGroup);
		},

		setDragElId: function (id) {
			this.dragElId = id;
		},

		setHandleElId: function (id) {
			if (typeof id !== "string") {
				id = Ext.id(id);
			}
			this.handleElId = id;
			this.DDM.regHandle(this.id, id);
		},

		removeHandleElId: function (id) {
			this.DDM.unregHandle(this.id, id);
		},

		setOuterHandleElId: function (id) {
			if (typeof id !== "string") {
				id = Ext.id(id);
			}
			Event.on(id, "mousedown",
				this.handleMouseDown, this);
			this.setHandleElId(id);
			this.outerHandlesCount = this.outerHandlesCount + 1;
			this.hasOuterHandles = true;
		},

		removeOuterHandleElId: function (id) {
			Event.un(id, "mousedown",
				this.handleMouseDown, this);
			this.removeHandleElId(id);
			this.outerHandlesCount = this.outerHandlesCount - 1;
			if (this.outerHandlesCount < 1) {
				this.hasOuterHandles = false;
			}
		},

		unreg: function () {
			Event.un(this.id, "mousedown",
                this.handleMouseDown);
			this._domRef = null;
			this.DDM._remove(this);
		},

		destroy: function () {
			this.unreg();
		},

		isLocked: function () {
			return (this.DDM.isLocked() || this.locked);
		},

		handleMouseDown: function (e, oDD) {
			if (this.primaryButtonOnly && e.button != 0) {
				return;
			}

			if (this.isLocked()) {
				return;
			}

			this.DDM.refreshCache(this.groups);

			var pt = new Ext.lib.Point(Ext.lib.Event.getPageX(e), Ext.lib.Event.getPageY(e));
			if (!this.hasOuterHandles && !this.DDM.isOverTarget(pt, this)) {
			} else {
				if (this.clickValidator(e)) {
					this.setStartPosition();

					this.b4MouseDown(e);
					this.onMouseDown(e);

					this.DDM.handleMouseDown(e, this);

					this.DDM.stopEvent(e);
				} else {

				}
			}
		},

		clickValidator: function (e) {
			var target = e.getTarget();
			return (this.isValidHandleChild(target) &&
                    (this.id == this.handleElId ||
                        this.DDM.handleWasClicked(target, this.id)));
		},

		addInvalidHandleType: function (tagName) {
			var type = tagName.toUpperCase();
			this.invalidHandleTypes[type] = type;
		},

		addInvalidHandleId: function (id) {
			if (typeof id !== "string") {
				id = Ext.id(id);
			}
			this.invalidHandleIds[id] = id;
		},

		addInvalidHandleClass: function (cssClass) {
			this.invalidHandleClasses.push(cssClass);
		},

		removeInvalidHandleType: function (tagName) {
			var type = tagName.toUpperCase();

			delete this.invalidHandleTypes[type];
		},

		removeInvalidHandleId: function (id) {
			if (typeof id !== "string") {
				id = Ext.id(id);
			}
			delete this.invalidHandleIds[id];
		},

		removeInvalidHandleClass: function (cssClass) {
			for (var i = 0, len = this.invalidHandleClasses.length; i < len; ++i) {
				if (this.invalidHandleClasses[i] == cssClass) {
					delete this.invalidHandleClasses[i];
				}
			}
		},

		isValidHandleChild: function (node) {

			var valid = true;

			var nodeName;
			try {
				nodeName = node.nodeName.toUpperCase();
			} catch (e) {
				nodeName = node.nodeName;
			}
			valid = valid && !this.invalidHandleTypes[nodeName];
			valid = valid && !this.invalidHandleIds[node.id];

			for (var i = 0, len = this.invalidHandleClasses.length; valid && i < len; ++i) {
				valid = !Ext.fly(node).hasClass(this.invalidHandleClasses[i]);
			}

			return valid;

		},

		setXTicks: function (iStartX, iTickSize) {
			this.xTicks = [];
			this.xTickSize = iTickSize;

			var tickMap = {};

			for (var i = this.initPageX; i >= this.minX; i = i - iTickSize) {
				if (!tickMap[i]) {
					this.xTicks[this.xTicks.length] = i;
					tickMap[i] = true;
				}
			}

			for (i = this.initPageX; i <= this.maxX; i = i + iTickSize) {
				if (!tickMap[i]) {
					this.xTicks[this.xTicks.length] = i;
					tickMap[i] = true;
				}
			}

			this.xTicks.sort(this.DDM.numericSort);
		},

		setYTicks: function (iStartY, iTickSize) {
			this.yTicks = [];
			this.yTickSize = iTickSize;

			var tickMap = {};

			for (var i = this.initPageY; i >= this.minY; i = i - iTickSize) {
				if (!tickMap[i]) {
					this.yTicks[this.yTicks.length] = i;
					tickMap[i] = true;
				}
			}

			for (i = this.initPageY; i <= this.maxY; i = i + iTickSize) {
				if (!tickMap[i]) {
					this.yTicks[this.yTicks.length] = i;
					tickMap[i] = true;
				}
			}

			this.yTicks.sort(this.DDM.numericSort);
		},

		setXConstraint: function (iLeft, iRight, iTickSize) {
			this.leftConstraint = iLeft;
			this.rightConstraint = iRight;

			this.minX = this.initPageX - iLeft;
			this.maxX = this.initPageX + iRight;
			if (iTickSize) { this.setXTicks(this.initPageX, iTickSize); }

			this.constrainX = true;
		},

		clearConstraints: function () {
			this.constrainX = false;
			this.constrainY = false;
			this.clearTicks();
		},

		clearTicks: function () {
			this.xTicks = null;
			this.yTicks = null;
			this.xTickSize = 0;
			this.yTickSize = 0;
		},

		setYConstraint: function (iUp, iDown, iTickSize) {
			this.topConstraint = iUp;
			this.bottomConstraint = iDown;

			this.minY = this.initPageY - iUp;
			this.maxY = this.initPageY + iDown;
			if (iTickSize) { this.setYTicks(this.initPageY, iTickSize); }

			this.constrainY = true;
		},

		resetConstraints: function () {
			if (this.initPageX || this.initPageX === 0) {

				var dx = (this.maintainOffset) ? this.lastPageX - this.initPageX : 0;
				var dy = (this.maintainOffset) ? this.lastPageY - this.initPageY : 0;

				this.setInitPosition(dx, dy);
			} else {
				this.setInitPosition();
			}

			if (this.constrainX) {
				this.setXConstraint(this.leftConstraint,
                                 this.rightConstraint,
                                 this.xTickSize);
			}
			if (this.constrainY) {
				this.setYConstraint(this.topConstraint,
                                 this.bottomConstraint,
                                 this.yTickSize);
			}
		},

		getTick: function (val, tickArray) {
			if (!tickArray) {
				return val;
			} else if (tickArray[0] >= val) {
				return tickArray[0];
			} else {
				for (var i = 0, len = tickArray.length; i < len; ++i) {
					var next = i + 1;
					if (tickArray[next] && tickArray[next] >= val) {
						var diff1 = val - tickArray[i];
						var diff2 = tickArray[next] - val;
						return (diff2 > diff1) ? tickArray[i] : tickArray[next];
					}
				}
				return tickArray[tickArray.length - 1];
			}
		},
		toString: function () {
			return ("DragDrop " + this.id);
		},

		isTargetVisible: function (e) {
			return true;
		}

	};

})();

if (!Ext.dd.DragDropMgr) {
	Ext.dd.DragDropMgr = function () {
		var Event = Ext.EventManager;

		return {
			ids: {},

			handleIds: {},

			dragCurrent: null,

			dragOvers: {},

			deltaX: 0,

			deltaY: 0,

			preventDefault: true,

			stopPropagation: true,

			initialized: false,

			locked: false,

			init: function () {
				this.initialized = true;
			},

			POINT: 0,

			INTERSECT: 1,

			mode: 0,

			_execOnAll: function (sMethod, args) {
				for (var i in this.ids) {
					for (var j in this.ids[i]) {
						var oDD = this.ids[i][j];
						if (!this.isTypeOfDD(oDD)) {
							continue;
						}
						oDD[sMethod].apply(oDD, args);
					}
				}
			},

			_onLoad: function () {
				this.init();
				Event.on(document, "mousedown", this.handleDocMouseDown, this, true);
				Event.on(document, "mouseup", this.handleMouseUp, this, true);
				Event.on(document, "mousemove", this.handleMouseMove, this, true);
				Event.on(window, "unload", this._onUnload, this, true);
				Event.on(window, "resize", this._onResize, this, true);
			},

			_onResize: function (e) {
				this._execOnAll("resetConstraints", []);
			},

			lock: function () { this.locked = true; },

			unlock: function () { this.locked = false; },

			isLocked: function () { return this.locked; },

			locationCache: {},

			useCache: true,

			clickPixelThresh: 3,

			clickTimeThresh: 350,

			dragThreshMet: false,

			clickTimeout: null,

			startX: 0,

			startY: 0,

			regDragDrop: function (oDD, sGroup) {
				if (!this.initialized) { this.init(); }
				if (!this.ids[sGroup]) {
					this.ids[sGroup] = {};
				}
				this.ids[sGroup][oDD.id] = oDD;
			},

			removeDDFromGroup: function (oDD, sGroup) {
				if (!this.ids[sGroup]) {
					this.ids[sGroup] = {};
				}

				var obj = this.ids[sGroup];
				if (obj && obj[oDD.id]) {
					delete obj[oDD.id];
				}
			},

			_remove: function (oDD) {
				for (var g in oDD.groups) {
					if (g && this.ids[g][oDD.id]) {
						delete this.ids[g][oDD.id];
					}
				}
				delete this.handleIds[oDD.id];
			},

			regHandle: function (sDDId, sHandleId) {
				if (!this.handleIds[sDDId]) {
					this.handleIds[sDDId] = {};
				}
				this.handleIds[sDDId][sHandleId] = sHandleId;
			},

			unregHandle: function (sDDId, sHandleId) {
				delete this.handleIds[sDDId][sHandleId];
			},

			getRelated: function (p_oDD, bTargetsOnly) {
				var oDDs = [];
				for (var i in p_oDD.groups) {
					for (j in this.ids[i]) {
						var dd = this.ids[i][j];
						if (!this.isTypeOfDD(dd)) {
							continue;
						}
						if (!bTargetsOnly || dd.isTarget) {
							oDDs[oDDs.length] = dd;
						}
					}
				}
				return oDDs;
			},

			isLegalTarget: function (oDD, oTargetDD) {
				var targets = this.getRelated(oDD, true);
				for (var i = 0, len = targets.length; i < len; ++i) {
					if (targets[i].id == oTargetDD.id) {
						return true;
					}
				}

				return false;
			},

			isTypeOfDD: function (oDD) {
				return (oDD && oDD.__ygDragDrop);
			},

			isHandle: function (sDDId, sHandleId) {
				return (this.handleIds[sDDId] &&
                            this.handleIds[sDDId][sHandleId]);
			},

			getDDById: function (id, groups) {
				if (groups) {
					for (var sGroup in groups) {
						if ("string" != typeof sGroup) {
							continue;
						}
						if (this.ids[sGroup][id]) {
							return this.ids[sGroup][id];
						}
					}
					return null;
				}
				for (var i in this.ids) {
					if (this.ids[i][id]) {
						return this.ids[i][id];
					}
				}
				return null;
			},

			handleDocMouseDown: function (e) {
				var dragCurrent = this.dragCurrent;
				if (!dragCurrent || dragCurrent.stopDragOnMouseDown !== true ||
							dragCurrent.dragOnMouseDownStarted !== true || dragCurrent.isMouseUpHandled !== true) {
					return;
				}
				dragCurrent.isMouseUpHandled = false;
				dragCurrent.dragOnMouseDownStarted = false;
				dragCurrent.DDM.handleMouseUp(e);
			},

			handleMouseDown: function (e, oDD) {
				var dragCurrent = this.dragCurrent;
				if (dragCurrent && dragCurrent.stopDragOnMouseDown === true &&
							dragCurrent.dragOnMouseDownStarted === true) {
					return;
				}
				if (Ext.QuickTips) {
					Ext.QuickTips.disable();
				}
				this.currentTarget = e.getTarget();
				dragCurrent = this.dragCurrent = oDD;
				var el = oDD.getEl();
				this.startX = e.getPageX();
				this.startY = e.getPageY();
				this.deltaX = this.startX - el.offsetLeft;
				this.deltaY = this.startY - el.offsetTop;
				this.dragThreshMet = false;
				if (dragCurrent && dragCurrent.stopDragOnMouseDown === true) {
					dragCurrent.dragOnMouseDownStarted = true;
					dragCurrent.DDM.handleMouseMove(e);
					return;
				}
				this.clickTimeout = setTimeout(function () {
					var DDM = Ext.dd.DDM;
					DDM.startDrag(DDM.startX, DDM.startY);
				},
					this.clickTimeThresh);
			},

			startDrag: function (x, y) {
				clearTimeout(this.clickTimeout);
				if (this.dragCurrent) {
					this.dragCurrent.b4StartDrag(x, y);
					this.dragCurrent.startDrag(x, y);
				}
				this.dragThreshMet = true;
			},

			handleMouseUp: function (e) {
				var dragCurrent = this.dragCurrent;
				if (!dragCurrent) {
					return;
				}
				if (dragCurrent.stopDragOnMouseDown === true && dragCurrent.dragOnMouseDownStarted === true) {
					dragCurrent.isMouseUpHandled = true;
					return;
				}
				if (Ext.QuickTips) {
					Ext.QuickTips.enable();
				}
				clearTimeout(this.clickTimeout);
				if (this.dragThreshMet) {
					this.fireEvents(e, true);
				} else {
				}
				this.stopDrag(e);
				this.stopEvent(e);
				e.browserEvent.eventCanceled = true;
			},

			stopEvent: function (e) {
				if (this.stopPropagation) {
					e.stopPropagation();
				}
				if (this.preventDefault) {
					e.preventDefault();
				}
			},

			stopDrag: function (e) {
				if (this.dragCurrent) {
					if (this.dragThreshMet) {
						this.dragCurrent.b4EndDrag(e);
						this.dragCurrent.endDrag(e);
					}

					this.dragCurrent.onMouseUp(e);
				}

				this.dragCurrent = null;
				this.dragOvers = {};
			},

			handleMouseMove: function (e) {
				if (!this.dragCurrent) {
					return true;
				}
				if (Ext.isIE && (e.button !== 0 && e.button !== 1 && e.button !== 2) &&
							this.dragCurrent.stopDragOnMouseDown !== true) {
					this.stopEvent(e);
					return this.handleMouseUp(e);
				}
				if (!this.dragThreshMet) {
					var diffX = Math.abs(this.startX - e.getPageX());
					var diffY = Math.abs(this.startY - e.getPageY());
					if (diffX > this.clickPixelThresh || diffY > this.clickPixelThresh) {
						this.e = e;
						this.startDrag(this.startX, this.startY);
					}
				}
				if (this.dragThreshMet) {
					this.dragCurrent.b4Drag(e);
					this.dragCurrent.onDrag(e);
					if (!this.dragCurrent.moveOnly) {
						if (this.dragCurrent.proxy && !this.dragCurrent.proxy.isVisible) {
						} else {
							this.fireEvents(e, false);
						}
					}
				}
				this.stopEvent(e);
				return true;
			},

			fireEvents: function (e, isDrop) {
				var dc = this.dragCurrent;
				if (!dc || dc.isLocked()) {
					return;
				}
				var pt = e.getPoint();
				var oldOvers = [];
				var outEvts = [];
				var overEvts = [];
				var dropEvts = [];
				var enterEvts = [];
				var deepestDropTarget;
				var maxOutPriority;
				var maxEnterPriority;
				var maxOverPriority;
				var maxDropPriority;
				for (var i in this.dragOvers) {
					var ddo = this.dragOvers[i];
					if (!this.isTypeOfDD(ddo)) {
						continue;
					}

					if (!this.isOverTarget(pt, ddo, this.mode)) {
						if (ddo.priority != undefined) {
							if (maxOutPriority == null || (ddo.priority < maxOutPriority)) {
								maxOutPriority = ddo.priority;
							}
						}
						outEvts.push(ddo);
					}

					oldOvers[i] = true;
					delete this.dragOvers[i];
				}
				for (var sGroup in dc.groups) {
					if ("string" != typeof sGroup) {
						continue;
					}
					for (i in this.ids[sGroup]) {
						var oDD = this.ids[sGroup][i];
						if (!this.isTypeOfDD(oDD)) {
							continue;
						}
						if (oDD.isTarget && !oDD.isLocked() && (oDD != dc) && oDD.isTargetVisible(e)) {
							if (this.isOverTarget(pt, oDD, this.mode)) {
								if ((!deepestDropTarget || deepestDropTarget.contains(oDD.el))) {
									deepestDropTarget = oDD.el;
								}
								if (isDrop) {
									if (oDD.priority != undefined) {
										if (maxDropPriority == null || (oDD.priority < maxDropPriority)) {
											maxDropPriority = oDD.priority;
										}
									}
									dropEvts.push(oDD);
								} else {
									if (!oldOvers[oDD.id]) {
										if (oDD.priority != undefined) {
											if (maxEnterPriority == null ||
														(oDD.priority < maxEnterPriority)) {
												maxEnterPriority = oDD.priority;
											}
										}
										enterEvts.push(oDD);
									} else {
										if (oDD.priority != undefined) {
											if (maxOverPriority == null ||
															(oDD.priority < maxOverPriority)) {
												maxOverPriority = oDD.priority;
											}
										}
										overEvts.push(oDD);
									}
									this.dragOvers[oDD.id] = oDD;
								}
							}
						}
					}
				}
				if (this.mode) {
					if (outEvts.length) {
						dc.b4DragOut(e, outEvts);
						dc.onDragOut(e, outEvts);
					}
					if (enterEvts.length) {
						dc.onDragEnter(e, enterEvts);
					}
					if (overEvts.length) {
						dc.b4DragOver(e, overEvts);
						dc.onDragOver(e, overEvts);
					}
					if (dropEvts.length) {
						dc.b4DragDrop(e, dropEvts);
						dc.onDragDrop(e, dropEvts);
					}
				} else {
					var len = 0;
					for (i = 0, len = outEvts.length; i < len; ++i) {
						if (outEvts[i].priority != undefined &&
									outEvts[i].priority > maxOutPriority) {
							continue;
						}
						dc.b4DragOut(e, outEvts[i].id);
						dc.onDragOut(e, outEvts[i].id);
					}
					for (i = 0, len = enterEvts.length; i < len; ++i) {
						if (enterEvts[i].priority != undefined &&
									enterEvts[i].priority > maxEnterPriority) {
							continue;
						}
						dc.onDragEnter(e, enterEvts[i].id);
					}
					for (i = 0, len = overEvts.length; i < len; ++i) {
						if (overEvts[i].priority != undefined &&
									overEvts[i].priority > maxOverPriority) {
							continue;
						}
						if (deepestDropTarget != undefined &&
									deepestDropTarget != overEvts[i].el) {
							dc.b4DragOut(e, overEvts[i].id);
							dc.onDragOut(e, overEvts[i].id);
							continue;
						}
						dc.b4DragOver(e, overEvts[i].id);
						dc.onDragOver(e, overEvts[i].id);
					}
					delete e.cancelDrop;
					for (i = 0, len = dropEvts.length; i < len; ++i) {
						if (dropEvts[i].priority != undefined &&
									dropEvts[i].priority > maxDropPriority) {
							continue;
						}
						if (deepestDropTarget != undefined &&
									deepestDropTarget != dropEvts[i].el) {
							dc.b4DragOut(e, dropEvts[i].id);
							dc.onDragOut(e, dropEvts[i].id);
							continue;
						}
						dc.b4DragDrop(e, dropEvts[i].id);
						dc.onDragDrop(e, dropEvts[i].id);
					}
				}

				if (isDrop && !dropEvts.length) {
					dc.onInvalidDrop(e);
				}
			},

			getBestMatch: function (dds) {
				var winner = null;
				var len = dds.length;

				if (len == 1) {
					winner = dds[0];
				} else {
					for (var i = 0; i < len; ++i) {
						var dd = dds[i];

						if (dd.cursorIsOver) {
							winner = dd;
							break;
						} else {
							if (!winner || winner.overlap.getArea() < dd.overlap.getArea()) {
								winner = dd;
							}
						}
					}
				}
				return winner;
			},

			refreshCache: function (groups) {
				for (var sGroup in groups) {
					if ("string" != typeof sGroup) {
						continue;
					}
					for (var i in this.ids[sGroup]) {
						var oDD = this.ids[sGroup][i];

						if (this.isTypeOfDD(oDD)) {
							var loc = this.getLocation(oDD);
							if (loc) {
								this.locationCache[oDD.id] = loc;
							} else {
								delete this.locationCache[oDD.id];
							}
						}
					}
				}
			},

			verifyEl: function (el) {
				if (el) {
					var parent;
					if (Ext.isIE) {
						try {
							parent = el.offsetParent;
						} catch (e) { }
					} else {
						parent = el.offsetParent;
					}
					if (parent) {
						return true;
					}
				}
				return false;
			},

			getLocation: function (oDD) {
				if (!this.isTypeOfDD(oDD)) {
					return null;
				}

				var el = oDD.getEl(), pos, x1, x2, y1, y2, t, r, b, l;

				try {
					pos = Ext.lib.Dom.getXY(el);
				} catch (e) { }

				if (!pos) {
					return null;
				}

				x1 = pos[0];
				x2 = x1 + el.offsetWidth;
				y1 = pos[1];
				if (el.offsetHeight) {
					y2 = y1 + el.offsetHeight;
				} else {
					var offsetHeight = (el.parentElement) ?
							el.parentElement.offsetHeight || 0 : 0;
					y2 = y1 + offsetHeight;
				}

				t = y1 - oDD.padding[0];
				r = x2 + oDD.padding[1];
				b = y2 + oDD.padding[2];
				l = x1 - oDD.padding[3];

				return new Ext.lib.Region(t, r, b, l);
			},

			isOverTarget: function (pt, oTarget, intersect) {
				var loc = this.locationCache[oTarget.id];
				if (!loc || !this.useCache) {
					loc = this.getLocation(oTarget);
					this.locationCache[oTarget.id] = loc;
				}

				if (!loc) {
					return false;
				}

				oTarget.cursorIsOver = loc.contains(pt);

				var dc = this.dragCurrent;
				if (!dc || !dc.getTargetCoord ||
                    (!intersect && !dc.constrainX && !dc.constrainY)) {
					return oTarget.cursorIsOver;
				}

				oTarget.overlap = null;

				var pos = dc.getTargetCoord(pt.x, pt.y);

				var el = dc.getDragEl();
				var curRegion = new Ext.lib.Region(pos.y,
						pos.x + el.offsetWidth,
						pos.y + el.offsetHeight,
						pos.x);
				var overlap = curRegion.intersect(loc);

				if (overlap) {
					oTarget.overlap = overlap;
					return (intersect) ? true : oTarget.cursorIsOver;
				} else {
					return false;
				}
			},

			_onUnload: function (e, me) {
				Ext.dd.DragDropMgr.unregAll();
			},

			unregAll: function () {
				if (this.dragCurrent) {
					this.stopDrag();
					this.dragCurrent = null;
				}

				this._execOnAll("unreg", []);

				for (var i in this.elementCache) {
					delete this.elementCache[i];
				}

				this.elementCache = {};
				this.ids = {};
			},

			elementCache: {},

			getElWrapper: function (id) {
				var oWrapper = this.elementCache[id];
				if (!oWrapper || !oWrapper.el) {
					oWrapper = this.elementCache[id] =
                    new this.ElementWrapper(Ext.getDom(id));
				}
				return oWrapper;
			},

			getElement: function (id) {
				return Ext.getDom(id);
			},

			getCss: function (id) {
				var el = Ext.getDom(id);
				return (el) ? el.style : null;
			},

			ElementWrapper: function (el) {
				this.el = el || null;
				this.id = this.el && el.id;
				this.css = this.el && el.style;
			},

			getPosX: function (el) {
				return Ext.lib.Dom.getX(el);
			},

			getPosY: function (el) {
				return Ext.lib.Dom.getY(el);
			},

			swapNode: function (n1, n2) {
				if (n1.swapNode) {
					n1.swapNode(n2);
				} else {
					var p = n2.parentNode;
					var s = n2.nextSibling;

					if (s == n1) {
						p.insertBefore(n1, n2);
					} else if (n2 == n1.nextSibling) {
						p.insertBefore(n2, n1);
					} else {
						n1.parentNode.replaceChild(n2, n1);
						p.insertBefore(n1, s);
					}
				}
			},

			getScroll: function () {
				var t, l, dde = document.documentElement, db = document.body;
				if (dde && (dde.scrollTop || dde.scrollLeft)) {
					t = dde.scrollTop;
					l = dde.scrollLeft;
				} else if (db) {
					t = db.scrollTop;
					l = db.scrollLeft;
				} else {

				}
				return { top: t, left: l };
			},

			getStyle: function (el, styleProp) {
				return Ext.fly(el).getStyle(styleProp);
			},

			getScrollTop: function () { return this.getScroll().top; },

			getScrollLeft: function () { return this.getScroll().left; },

			moveToEl: function (moveEl, targetEl) {
				var aCoord = Ext.lib.Dom.getXY(targetEl);
				Ext.lib.Dom.setXY(moveEl, aCoord);
			},

			numericSort: function (a, b) { return (a - b); },

			_timeoutCount: 0,

			_addListeners: function () {
				var DDM = Ext.dd.DDM;
				if (Ext.lib.Event && document) {
					DDM._onLoad();
				} else {
					if (DDM._timeoutCount > 2000) {
					} else {
						setTimeout(DDM._addListeners, 10);
						if (document && document.body) {
							DDM._timeoutCount += 1;
						}
					}
				}
			},

			handleWasClicked: function (node, id) {
				if (this.isHandle(id, node.id)) {
					return true;
				} else {
					var p = node.parentNode;

					while (p) {
						if (this.isHandle(id, p.id)) {
							return true;
						} else {
							p = p.parentNode;
						}
					}
				}
				return false;
			}
		};
	} ();

	Ext.dd.DDM = Ext.dd.DragDropMgr;
	Ext.dd.DDM._addListeners();
}

Ext.dd.DD = function (id, sGroup, config) {
	if (id) {
		this.init(id, sGroup, config);
	}
};

Ext.extend(Ext.dd.DD, Ext.dd.DragDrop, {
	scroll: true,

	autoOffset: function (iPageX, iPageY) {
		var x = iPageX - this.startPageX;
		var y = iPageY - this.startPageY;
		this.setDelta(x, y);
	},

	setDelta: function (iDeltaX, iDeltaY) {
		this.deltaX = iDeltaX;
		this.deltaY = iDeltaY;
	},

	setDragElPos: function (iPageX, iPageY) {
		var el = this.getDragEl();
		this.alignElWithMouse(el, iPageX, iPageY);
	},

	alignElWithMouse: function (el, iPageX, iPageY) {
		var oCoord = this.getTargetCoord(iPageX, iPageY);
		var fly = el.dom ? el : Ext.fly(el, '_dd');
		if (!this.deltaSetXY) {
			var aCoord = [oCoord.x, oCoord.y];
			fly.setXY(aCoord);
			var newLeft = fly.getLeft(true);
			var newTop = fly.getTop(true);
			this.deltaSetXY = [newLeft - oCoord.x, newTop - oCoord.y];
		} else {
			fly.setLeftTop(oCoord.x + this.deltaSetXY[0], oCoord.y + this.deltaSetXY[1]);
		}

		this.cachePosition(oCoord.x, oCoord.y);
		this.autoScroll(oCoord.x, oCoord.y, el.offsetHeight, el.offsetWidth);
		return oCoord;
	},

	cachePosition: function (iPageX, iPageY) {
		if (iPageX) {
			this.lastPageX = iPageX;
			this.lastPageY = iPageY;
		} else {
			var aCoord = Ext.lib.Dom.getXY(this.getEl());
			this.lastPageX = aCoord[0];
			this.lastPageY = aCoord[1];
		}
	},

	autoScroll: function (x, y, h, w) {
		if (this.scroll) {
			var clientH = Ext.lib.Dom.getViewHeight();
			var clientW = Ext.lib.Dom.getViewWidth();
			var st = this.DDM.getScrollTop();
			var sl = this.DDM.getScrollLeft();
			var bot = h + y;
			var right = w + x;
			var toBot = (clientH + st - y - this.deltaY);
			var toRight = (clientW + sl - x - this.deltaX);
			var thresh = 40;
			var scrAmt = (document.all) ? 80 : 30;

			if (bot > clientH && toBot < thresh) {
				window.scrollTo(sl, st + scrAmt);
			}

			if (y < st && st > 0 && y - st < thresh) {
				window.scrollTo(sl, st - scrAmt);
			}

			if (right > clientW && toRight < thresh) {
				window.scrollTo(sl + scrAmt, st);
			}

			if (x < sl && sl > 0 && x - sl < thresh) {
				window.scrollTo(sl - scrAmt, st);
			}
		}
	},

	getTargetCoord: function (iPageX, iPageY) {
		var x = iPageX - this.deltaX;
		var y = iPageY - this.deltaY;

		if (this.constrainX) {
			if (x < this.minX) { x = this.minX; }
			if (x > this.maxX) { x = this.maxX; }
		}

		if (this.constrainY) {
			if (y < this.minY) { y = this.minY; }
			if (y > this.maxY) { y = this.maxY; }
		}

		x = this.getTick(x, this.xTicks);
		y = this.getTick(y, this.yTicks);

		return { x: x, y: y };
	},

	applyConfig: function () {
		Ext.dd.DD.superclass.applyConfig.call(this);
		this.scroll = (this.config.scroll !== false);
	},

	b4MouseDown: function (e) {
		this.autoOffset(e.getPageX(),
                            e.getPageY());
	},

	b4Drag: function (e) {
		this.setDragElPos(e.getPageX(),
                            e.getPageY());
	},

	toString: function () {
		return ("DD " + this.id);
	}
});

Ext.dd.DDProxy = function (id, sGroup, config) {
	if (id) {
		this.init(id, sGroup, config);
		this.initFrame();
	}
};

Ext.dd.DDProxy.dragElId = "ygddfdiv";

Ext.extend(Ext.dd.DDProxy, Ext.dd.DD, {
	resizeFrame: true,
	centerFrame: false,

	createFrame: function () {
		var self = this;
		var body = document.body;

		if (!body || !body.firstChild) {
			setTimeout(function () { self.createFrame(); }, 50);
			return;
		}

		var div = this.getDragEl();

		if (!div) {
			div = document.createElement("div");
			div.id = this.dragElId;
			var s = div.style;

			s.position = "absolute";
			s.visibility = "hidden";
			s.cursor = "move";
			s.border = "2px solid #aaa";
			s.zIndex = 999;

			body.insertBefore(div, body.firstChild);
		}
	},

	initFrame: function () {
		this.createFrame();
	},

	applyConfig: function () {
		Ext.dd.DDProxy.superclass.applyConfig.call(this);

		this.resizeFrame = (this.config.resizeFrame !== false);
		this.centerFrame = (this.config.centerFrame);
		this.setDragElId(this.config.dragElId || Ext.dd.DDProxy.dragElId);
	},

	showFrame: function (iPageX, iPageY) {
		var el = this.getEl();
		var dragEl = this.getDragEl();
		var s = dragEl.style;

		this._resizeProxy();

		if (this.centerFrame) {
			this.setDelta(Math.round(parseInt(s.width, 10) / 2),
                           Math.round(parseInt(s.height, 10) / 2));
		}

		this.setDragElPos(iPageX, iPageY);

		Ext.fly(dragEl).show();
	},

	_resizeProxy: function () {
		if (this.resizeFrame) {
			var el = this.getEl();
			Ext.fly(this.getDragEl()).setSize(el.offsetWidth, el.offsetHeight);
		}
	},

	b4MouseDown: function (e) {
		var x = e.getPageX();
		var y = e.getPageY();
		this.autoOffset(x, y);
		this.setDragElPos(x, y);
	},

	b4StartDrag: function (x, y) {
		this.showFrame(x, y);
	},

	b4EndDrag: function (e) {
		Ext.fly(this.getDragEl()).hide();
	},

	endDrag: function (e) {
		var lel = this.getEl();
		var del = this.getDragEl();

		del.style.visibility = "";

		this.beforeMove();

		lel.style.visibility = "hidden";
		Ext.dd.DDM.moveToEl(lel, del);
		del.style.visibility = "hidden";
		lel.style.visibility = "";

		this.afterDrag();
	},

	beforeMove: function () {

	},

	afterDrag: function () {

	},

	toString: function () {
		return ("DDProxy " + this.id);
	}

});

Ext.dd.DDTarget = function (id, sGroup, config) {
	if (id) {
		this.initTarget(id, sGroup, config);
	}
};

Ext.extend(Ext.dd.DDTarget, Ext.dd.DragDrop, {
	toString: function () {
		return ("DDTarget " + this.id);
	}
});

Ext.dd.DragTracker = function (config) {
	Ext.apply(this, config);
	this.addEvents(
        'mousedown',
        'mouseup',
        'mousemove',
        'dragstart',
        'dragend',
        'drag'
    );

	this.dragRegion = new Ext.lib.Region(0, 0, 0, 0);

	if (this.el) {
		this.initEl(this.el);
	}
}

Ext.extend(Ext.dd.DragTracker, Ext.util.Observable, {
	active: false,
	tolerance: 5,
	autoStart: false,

	initEl: function (el) {
		this.el = Ext.get(el);
		el.on('mousedown', this.onMouseDown, this,
                this.delegate ? { delegate: this.delegate} : undefined);
	},

	destroy: function () {
		this.el.un('mousedown', this.onMouseDown, this);
	},

	onMouseDown: function (e, target) {
		if (this.fireEvent('mousedown', this, e) !== false && this.onBeforeStart(e) !== false) {
			this.startXY = this.lastXY = e.getXY();
			this.dragTarget = this.delegate ? target : this.el.dom;
			e.preventDefault();
			var doc = Ext.getDoc();
			doc.on('mouseup', this.onMouseUp, this);
			doc.on('mousemove', this.onMouseMove, this);
			doc.on('selectstart', this.stopSelect, this);
			if (this.autoStart) {
				this.timer = this.triggerStart.defer(this.autoStart === true ? 1000 : this.autoStart, this);
			}
		}
	},

	onMouseMove: function (e, target) {
		e.preventDefault();
		var xy = e.getXY(), s = this.startXY;
		this.lastXY = xy;
		if (!this.active) {
			if (Math.abs(s[0] - xy[0]) > this.tolerance || Math.abs(s[1] - xy[1]) > this.tolerance) {
				this.triggerStart();
			} else {
				return;
			}
		}
		this.fireEvent('mousemove', this, e);
		this.onDrag(e);
		this.fireEvent('drag', this, e);
	},

	onMouseUp: function (e) {
		var doc = Ext.getDoc();
		doc.un('mousemove', this.onMouseMove, this);
		doc.un('mouseup', this.onMouseUp, this);
		doc.un('selectstart', this.stopSelect, this);
		e.preventDefault();
		this.clearStart();
		this.active = false;
		delete this.elRegion;
		this.fireEvent('mouseup', this, e);
		this.onEnd(e);
		this.fireEvent('dragend', this, e);
	},

	triggerStart: function (isTimer) {
		this.clearStart();
		this.active = true;
		this.onStart(this.startXY);
		this.fireEvent('dragstart', this, this.startXY);
	},

	clearStart: function () {
		if (this.timer) {
			clearTimeout(this.timer);
			delete this.timer;
		}
	},

	stopSelect: function (e) {
		e.stopEvent();
		return false;
	},

	onBeforeStart: function (e) {

	},

	onStart: function (xy) {

	},

	onDrag: function (e) {

	},

	onEnd: function (e) {

	},

	getDragTarget: function () {
		return this.dragTarget;
	},

	getDragCt: function () {
		return this.el;
	},

	getXY: function (constrain) {
		return constrain ?
               this.constrainModes[constrain].call(this, this.lastXY) : this.lastXY;
	},

	getOffset: function (constrain) {
		var xy = this.getXY(constrain);
		var s = this.startXY;
		return [s[0] - xy[0], s[1] - xy[1]];
	},

	constrainModes: {
		'point': function (xy) {
			if (!this.elRegion) {
				this.elRegion = this.getDragCt().getRegion();
			}

			var dr = this.dragRegion;

			dr.left = xy[0];
			dr.top = xy[1];
			dr.right = xy[0];
			dr.bottom = xy[1];

			dr.constrainTo(this.elRegion);

			return [dr.left, dr.top];
		}
	}
});

Ext.dd.ScrollManager = function () {
	var ddm = Ext.dd.DragDropMgr;
	var els = {};
	var dragEl = null;
	var proc = {};

	var onStop = function (e) {
		dragEl = null;
		clearProc();
	};

	var triggerRefresh = function () {
		if (ddm.dragCurrent) {
			ddm.refreshCache(ddm.dragCurrent.groups);
		}
	};

	var doScroll = function () {
		if (ddm.dragCurrent) {
			var dds = Ext.dd.ScrollManager;
			var inc = proc.el.ddScrollConfig ?
					proc.el.ddScrollConfig.increment : dds.increment;
			if (!dds.animate) {
				if (proc.el.contentScroll) {
					proc.el.contentScroll(proc.dir, inc);
				} else if (proc.el.scroll(proc.dir, inc)) {
					triggerRefresh();
				}
			} else {
				if (proc.el.contentScroll) {
					proc.el.contentScroll(proc.dir, inc);
				} else {
					proc.el.scroll(proc.dir, inc, true, dds.animDuration, triggerRefresh);
				}
			}
		}
	};

	var clearProc = function () {
		if (proc.id) {
			clearInterval(proc.id);
		}
		proc.id = 0;
		proc.el = null;
		proc.dir = "";
	};

	var startProc = function (el, dir) {
		clearProc();
		proc.el = el;
		proc.dir = dir;
		var freq = (el.ddScrollConfig && el.ddScrollConfig.frequency) ?
                el.ddScrollConfig.frequency : Ext.dd.ScrollManager.frequency;
		proc.id = setInterval(doScroll, freq);
	};

	var onFire = function (e, isDrop) {
		if (isDrop || !ddm.dragCurrent) { return; }
		var dds = Ext.dd.ScrollManager;
		if (!dragEl || dragEl != ddm.dragCurrent) {
			dragEl = ddm.dragCurrent;

			dds.refreshCache();
		}

		var xy = Ext.lib.Event.getXY(e);
		var pt = new Ext.lib.Point(xy[0], xy[1]);
		for (var id in els) {
			var el = els[id], r = el._region;
			var c = el.ddScrollConfig ? el.ddScrollConfig : dds;
			var contentWrapR;
			if (c.contentWrap) {
				contentWrapR = c.contentWrap.getRegion();
			} else {
				contentWrapR = r;
			}
			if (r && contentWrapR.contains(pt) && el.isScrollable()) {
				if (r.bottom - pt.y <= c.vthresh) {
					if (proc.el != el) {
						startProc(el, "down");
					}
					return;
				} else if (r.right - pt.x <= c.hthresh) {
					if (proc.el != el) {
						startProc(el, "left");
					}
					return;
				} else if (pt.y - r.top <= c.vthresh) {
					if (proc.el != el) {
						startProc(el, "up");
					}
					return;
				} else if (pt.x - r.left <= c.hthresh) {
					if (proc.el != el) {
						startProc(el, "right");
					}
					return;
				}
			}
		}
		clearProc();
	};

	ddm.fireEvents = ddm.fireEvents.createSequence(onFire, ddm);
	ddm.stopDrag = ddm.stopDrag.createSequence(onStop, ddm);

	return {

		register: function (el) {
			if (Ext.isArray(el)) {
				for (var i = 0, len = el.length; i < len; i++) {
					this.register(el[i]);
				}
			} else {
				el = Ext.get(el);
				els[el.id] = el;
			}
		},

		unregister: function (el) {
			if (Ext.isArray(el)) {
				for (var i = 0, len = el.length; i < len; i++) {
					this.unregister(el[i]);
				}
			} else {
				el = Ext.get(el);
				delete els[el.id];
			}
		},

		vthresh: 25,

		hthresh: 25,

		increment: 100,

		frequency: 500,

		animate: true,

		animDuration: .4,

		refreshCache: function () {
			for (var id in els) {
				if (typeof els[id] == 'object') {
					els[id]._region = els[id].getRegion();
				}
			}
		}
	};
} ();

Ext.dd.Registry = function () {
	var elements = {};
	var handles = {};
	var autoIdSeed = 0;

	var getId = function (el, autogen) {
		if (typeof el == "string") {
			return el;
		}
		var id = el.id;
		if (!id && autogen !== false) {
			id = "extdd-" + (++autoIdSeed);
			el.id = id;
		}
		return id;
	};

	return {

		register: function (el, data) {
			data = data || {};
			if (typeof el == "string") {
				el = document.getElementById(el);
			}
			data.ddel = el;
			elements[getId(el)] = data;
			if (data.isHandle !== false) {
				handles[data.ddel.id] = data;
			}
			if (data.handles) {
				var hs = data.handles;
				for (var i = 0, len = hs.length; i < len; i++) {
					handles[getId(hs[i])] = data;
				}
			}
		},

		unregister: function (el) {
			var id = getId(el, false);
			var data = elements[id];
			if (data) {
				delete elements[id];
				if (data.handles) {
					var hs = data.handles;
					for (var i = 0, len = hs.length; i < len; i++) {
						delete handles[getId(hs[i], false)];
					}
				}
			}
		},

		getHandle: function (id) {
			if (typeof id != "string") {
				id = id.id;
			}
			return handles[id];
		},

		getHandleFromEvent: function (e) {
			var t = Ext.lib.Event.getTarget(e);
			return t ? handles[t.id] : null;
		},

		getTarget: function (id) {
			if (typeof id != "string") {
				id = id.id;
			}
			return elements[id];
		},

		getTargetFromEvent: function (e) {
			var t = Ext.lib.Event.getTarget(e);
			return t ? elements[t.id] || handles[t.id] : null;
		}
	};
} ();

Ext.dd.StatusProxy = function (config) {
	Ext.apply(this, config);
	this.id = this.id || Ext.id();
	this.el = new Ext.Layer({
		dh: {
			id: this.id, tag: "div", cls: "x-dd-drag-proxy " + this.dropNotAllowed, children: [
                { tag: "div", cls: "x-dd-drop-icon" },
                { tag: "div", cls: "x-dd-drag-ghost" }
            ]
		},
		shadow: !config || config.shadow !== false
	});
	this.ghost = Ext.get(this.el.dom.childNodes[1]);
	this.dropStatus = this.dropNotAllowed;
};

Ext.dd.StatusProxy.prototype = {
	isVisible: true,
	dropAllowed: "x-dd-drop-ok",
	dropNotAllowed: "x-dd-drop-nodrop",

	setStatus: function (cssClass) {
		cssClass = cssClass || this.dropNotAllowed;
		if (this.dropStatus != cssClass) {
			this.el.replaceClass(this.dropStatus, cssClass);
			this.dropStatus = cssClass;
		}
	},

	reset: function (clearGhost) {
		this.el.dom.className = "x-dd-drag-proxy " + this.dropNotAllowed;
		this.dropStatus = this.dropNotAllowed;
		if (clearGhost) {
			this.ghost.update("");
		}
	},

	update: function (html) {
		if (typeof html == "string") {
			this.ghost.update(html);
		} else {
			this.ghost.update("");
			html.style.margin = "0";
			this.ghost.dom.appendChild(html);
		}
		var el = this.ghost.dom.firstChild;
		if (el) {
			Ext.fly(el).setStyle(Ext.isIE ? 'styleFloat' : 'cssFloat', 'none');
		}
	},

	getEl: function () {
		return this.el;
	},

	getGhost: function () {
		return this.ghost;
	},

	hide: function (clear) {
		this.el.hide();
		if (clear) {
			this.reset(true);
		}
		this.isVisible = false;
	},

	stop: function () {
		if (this.anim && this.anim.isAnimated && this.anim.isAnimated()) {
			this.anim.stop();
		}
	},

	show: function () {
		this.el.show();
		this.isVisible = true;
	},

	sync: function () {
		this.el.sync();
	},

	repair: function (xy, callback, scope) {
		this.callback = callback;
		this.scope = scope;
		if (xy && this.animRepair !== false) {
			this.el.addClass("x-dd-drag-repair");
			this.el.hideUnders(true);
			this.anim = this.el.shift({
				duration: this.repairDuration || .5,
				easing: 'easeOut',
				xy: xy,
				stopFx: true,
				callback: this.afterRepair,
				scope: this
			});
		} else {
			this.afterRepair();
		}
	},

	afterRepair: function () {
		this.hide(true);
		if (typeof this.callback == "function") {
			this.callback.call(this.scope || this);
		}
		this.callback = null;
		this.scope = null;
	}
};

Ext.dd.DragSource = function (el, config) {
	this.el = Ext.get(el);
	if (!this.dragData) {
		this.dragData = {};
	}

	Ext.apply(this, config);

	if (!this.proxy) {
		this.proxy = new Ext.dd.StatusProxy();
	}
	Ext.dd.DragSource.superclass.constructor.call(this, this.el.dom, this.ddGroup || this.group,
			{ dragElId: this.proxy.id, resizeFrame: false, isTarget: false,
				scroll: this.scroll === true
			});
	this.dragging = false;
};

Ext.extend(Ext.dd.DragSource, Ext.dd.DDProxy, {
	dropAllowed: "x-dd-drop-ok",
	dropNotAllowed: "x-dd-drop-nodrop",

	getDragData: function (e) {
		return this.dragData;
	},

	onDragEnter: function (e, id) {
		var target = Ext.dd.DragDropMgr.getDDById(id, this.groups);
		this.cachedTarget = target;
		if (this.beforeDragEnter(target, e, id) !== false) {
			if (target.isNotifyTarget) {
				var status = target.notifyEnter(this, e, this.dragData);
				this.proxy.setStatus(status);
			} else {
				this.proxy.setStatus(this.dropAllowed);
			}
			if (this.afterDragEnter) {
				this.afterDragEnter(target, e, id);
			}
		}
	},

	beforeDragEnter: function (target, e, id) {
		return true;
	},

	alignElWithMouse: function () {
		Ext.dd.DragSource.superclass.alignElWithMouse.apply(this, arguments);
		this.proxy.sync();
	},

	onDragOver: function (e, id) {
		var target = this.cachedTarget || Ext.dd.DragDropMgr.getDDById(id, this.groups);
		if (this.beforeDragOver(target, e, id) !== false) {
			if (target.isNotifyTarget) {
				var status = target.notifyOver(this, e, this.dragData);
				this.proxy.setStatus(status);
			}
			if (this.afterDragOver) {
				this.afterDragOver(target, e, id);
			}
		}
	},

	beforeDragOver: function (target, e, id) {
		return true;
	},

	onDragOut: function (e, id) {
		var target = this.cachedTarget || Ext.dd.DragDropMgr.getDDById(id, this.groups);
		if (this.beforeDragOut(target, e, id) !== false) {
			if (target.isNotifyTarget) {
				target.notifyOut(this, e, this.dragData);
			}
			this.proxy.reset();
			if (this.afterDragOut) {

				this.afterDragOut(target, e, id);
			}
		}
		this.cachedTarget = null;
	},

	beforeDragOut: function (target, e, id) {
		return true;
	},

	onDragDrop: function (e, id) {
		var target = this.cachedTarget || Ext.dd.DragDropMgr.getDDById(id, this.groups);
		if (this.beforeDragDrop(target, e, id) !== false) {
			if (target.isNotifyTarget) {
				if (target.notifyDrop(this, e, this.dragData)) {
					this.onValidDrop(target, e, id);
				} else {
					this.onInvalidDrop(target, e, id);
				}
			} else {
				this.onValidDrop(target, e, id);
			}

			if (this.afterDragDrop) {

				this.afterDragDrop(target, e, id);
			}
		}
		delete this.cachedTarget;
	},

	beforeDragDrop: function (target, e, id) {
		return true;
	},

	onValidDrop: function (target, e, id) {
		this.hideProxy();
		if (this.afterValidDrop) {
			this.afterValidDrop(target, e, id);
		}
	},

	getRepairXY: function (e, data) {
		return this.el.getXY();
	},

	onInvalidDrop: function (target, e, id) {
		this.beforeInvalidDrop(target, e, id);
		if (this.cachedTarget) {
			if (this.cachedTarget.isNotifyTarget) {
				this.cachedTarget.notifyOut(this, e, this.dragData);
			}
			this.cacheTarget = null;
		}
		this.proxy.repair(this.getRepairXY(e, this.dragData), this.afterRepair, this);
		if (this.afterInvalidDrop) {
			this.afterInvalidDrop(e, id);
		}
	},

	afterRepair: function () {
		if (Ext.enableFx) {
			this.el.highlight(this.hlColor || "c3daf9");
		}
		this.dragging = false;
	},

	beforeInvalidDrop: function (target, e, id) {
		return true;
	},

	handleMouseDown: function (e) {
		if (this.dragging) {
			return;
		}
		var data = this.getDragData(e);
		if (data && this.onBeforeDrag(data, e) !== false) {
			this.dragData = data;
			Ext.dd.DragSource.superclass.handleMouseDown.apply(this, arguments);
		}
	},

	onBeforeDrag: function (data, e) {
		return true;
	},

	onStartDrag: Ext.emptyFn,

	startDrag: function (x, y) {
		this.proxy.reset();
		this.dragging = true;
		this.proxy.update("");
		if (this.onInitDrag(x, y)) {
			this.proxy.show();
		} else {
			this.hideProxy();
		}
	},

	onInitDrag: function (x, y) {
		var clone = this.el.dom.cloneNode(true);
		clone.id = Ext.id();
		this.proxy.update(clone);
		this.onStartDrag(x, y);
		return true;
	},

	getProxy: function () {
		return this.proxy;
	},

	hideProxy: function () {
		this.proxy.hide();
		this.proxy.reset(true);
		this.dragging = false;
	},

	triggerCacheRefresh: function () {
		Ext.dd.DDM.refreshCache(this.groups);
	},

	b4EndDrag: function (e) {
	},

	endDrag: function (e) {
		this.onEndDrag(this.dragData, e);
	},

	onEndDrag: function (data, e) {
	},

	autoOffset: function (x, y) {
		this.setDelta(-12, -20);
	}
});

Ext.dd.DropTarget = function (el, config) {
	this.el = Ext.get(el);
	Ext.apply(this, config);
	if (this.containerScroll) {
		Ext.dd.ScrollManager.register(this.el);
	}
	Ext.dd.DropTarget.superclass.constructor.call(this, this.el.dom, this.ddGroup || this.group,
			{ isTarget: true });
};

Ext.extend(Ext.dd.DropTarget, Ext.dd.DDTarget, {
	dropAllowed: "x-dd-drop-ok",
	dropNotAllowed: "x-dd-drop-nodrop",
	isTarget: true,
	isNotifyTarget: true,

	notifyEnter: function (dd, e, data) {
		if (this.overClass) {
			this.el.addClass(this.overClass);
		}
		return this.dropAllowed;
	},

	notifyOver: function (dd, e, data) {
		return this.dropAllowed;
	},

	notifyOut: function (dd, e, data) {
		if (this.overClass) {
			this.el.removeClass(this.overClass);
		}
	},

	hideDropHighligt: function (e) {
		if (e) {
			e.preventDefault();
		}
		var el = this.getDropZoneElement();
		el.select('.selectedDropElement').removeClass('selectedDropElement');
		el.select('.selectedDropElementParent').removeClass('selectedDropElementParent');
	},

	highlightDropElement: function (el) {
		if (el) {
			var elParent = el.findParent('.x-form-element', 5, true);
			this.hideDropHighligt();
			if (elParent) {
				elParent.addClass("selectedDropElementParent");
			}
			el.addClass("selectedDropElement");
		}
	},

	getDropZoneElement: function () {
		return Ext.get(this.contentEl || this.el);
	},

	notifyDrop: function (dd, e, data) {
		return false;
	}
});

Ext.dd.DragZone = function (el, config) {
	Ext.dd.DragZone.superclass.constructor.call(this, el, config);
	if (this.containerScroll) {
		Ext.dd.ScrollManager.register(this.el);
	}
};

Ext.extend(Ext.dd.DragZone, Ext.dd.DragSource, {

	getDragData: function (e) {
		return Ext.dd.Registry.getHandleFromEvent(e);
	},

	onInitDrag: function (x, y) {
		this.proxy.update(this.dragData.ddel.cloneNode(true));
		this.onStartDrag(x, y);
		return true;
	},

	afterRepair: function () {
		if (Ext.enableFx) {
			Ext.Element.fly(this.dragData.ddel).highlight(this.hlColor || "c3daf9");
		}
		this.dragging = false;
	},

	getRepairXY: function (e) {
		return Ext.Element.fly(this.dragData.ddel).getXY();
	}
});

Ext.dd.DropZone = function (el, config) {
	Ext.dd.DropZone.superclass.constructor.call(this, el, config);
};

Ext.extend(Ext.dd.DropZone, Ext.dd.DropTarget, {
	getTargetFromEvent: function (e) {
		return Ext.dd.Registry.getTargetFromEvent(e);
	},

	onNodeEnter: function (n, dd, e, data) {
	},

	onNodeOver: function (n, dd, e, data) {
		return this.dropAllowed;
	},

	onNodeOut: function (n, dd, e, data) {
	},

	onNodeDrop: function (n, dd, e, data) {
		return false;
	},

	onContainerOver: function (dd, e, data) {
		return this.dropNotAllowed;
	},

	onContainerDrop: function (dd, e, data) {
		return false;
	},

	notifyEnter: function (dd, e, data) {
		return this.dropNotAllowed;
	},

	notifyOver: function (dd, e, data) {
		var n = this.getTargetFromEvent(e);
		if (!n) {
			if (this.lastOverNode) {
				this.onNodeOut(this.lastOverNode, dd, e, data);
				this.lastOverNode = null;
			}
			return this.onContainerOver(dd, e, data);
		}
		if (this.lastOverNode != n) {
			if (this.lastOverNode) {
				this.onNodeOut(this.lastOverNode, dd, e, data);
			}
			this.onNodeEnter(n, dd, e, data);
			this.lastOverNode = n;
		}
		return this.onNodeOver(n, dd, e, data);
	},

	notifyOut: function (dd, e, data) {
		if (this.lastOverNode) {
			this.onNodeOut(this.lastOverNode, dd, e, data);
			this.lastOverNode = null;
		}
	},

	notifyDrop: function (dd, e, data) {
		if (this.lastOverNode) {
			this.onNodeOut(this.lastOverNode, dd, e, data);
			this.lastOverNode = null;
		}
		var n = this.getTargetFromEvent(e);
		return n ?
            this.onNodeDrop(n, dd, e, data) :
            this.onContainerDrop(dd, e, data);
	},

	triggerCacheRefresh: function () {
		Ext.dd.DDM.refreshCache(this.groups);
	}
});

Ext.ScrollBar = function () {
	var w3events;

	var initScrollBar = function (ct, cfg) {
		// --- initScrollBar code begin ---

		function initZoomDetectStyles() {
			zoomDetectDiv.styleRef.fontSize = "11px";
			zoomDetectDiv.styleRef.height = "1em";
			zoomDetectDiv.styleRef.width = "1em";
			zoomDetectDiv.styleRef.position = "absolute";
			zoomDetectDiv.styleRef.zIndex = "-999";
			zoomDetectDiv.fHide();
		}

		function initScrollViewPortStyles() {
			scrollViewPort.styleRef.width = "100px";
			scrollViewPort.styleRef.height = "100px"; //extCt.getHeight(true) + "px"; 
			scrollViewPort.styleRef.top = "0px";
			scrollViewPort.styleRef.left = "0px";
		}

		function initScrollWrapperStyles() {
			scrollWrapper.styleRef.width = ct.offsetWidth + 'px';
			scrollWrapper.styleRef.height = ct.offsetHeight + 'px';
			scrollViewPort.styleRef.width = postWidth + 'px';
			scrollViewPort.styleRef.height = postHeight + 'px';
			scrollWrapper.styleRef.position = 'absolute';
			scrollWrapper.styleRef.top = '0px';
			scrollWrapper.styleRef.left = '0px';
			//scrollWrapper.fHide();
		}

		// ---

		var doc = document, wD = window, nV = navigator;
		if (!doc.getElementById || !doc.createElement) return;
		var extCt = Ext.get(ct); ct = extCt.dom;
		var scrollBar = extCt.scrollBar || {};
		if (ct == null || nV.userAgent.indexOf('OmniWeb') != -1 ||
				((nV.userAgent.indexOf('AppleWebKit') != -1 || nV.userAgent.indexOf('Safari') != -1) &&
				!(typeof (HTMLElement) != "undefined" && HTMLElement.prototype)) || nV.vendor == 'KDE' ||
				(nV.platform.indexOf('Mac') != -1 && nV.userAgent.indexOf('MSIE') != -1)) {
			return;
		}
		scrollBar.cfg = Ext.apply({ useHScroll: true, useVScroll: true }, cfg);
		if (scrollBar.innerUpdate) {
			scrollBar.innerUpdate();
			return;
		};
		ct.id = ct.id || Ext.id(ct);
		var targetId = ct.id;
		ct.scrollBarData = new Object();
		var scrollBarData = ct.scrollBarData;
		scrollBarData.wheelAct = ["-2s", "2s"];
		scrollBarData.baseAct = ["-2s", "2s"];
		var contentWrapper = createDiv('contentwrapper', true),
				scrollViewPort = createDiv('scrollViewPort', true),
				scrollWrapper = createDiv('scrollwrapper', true);
		var zoomDetectDiv = createDiv('zoomdetectdiv', true),
				stdMode = false;
		extCt.setStyle('overflow', 'hidden');
		initZoomDetectStyles(zoomDetectDiv);
		var brdWidthLoss = extCt.getBorderWidth('lr'),
				brdHeightLoss = extCt.getBorderWidth('tb');
		var oScrollY = (ct.scrollTop) ? ct.scrollTop : 0,
				oScrollX = (ct.scrollLeft) ? ct.scrollLeft : 0;
		var urlBase = document.location.href, uReg = /#([^#.]*)$/;
		var focusProtectList = ['textarea', 'input', 'select'];
		scrollBarData.scroller = [];
		scrollBarData.forcedBar = [];
		scrollBarData.containerSize = [];
		scrollBarData.contentSize = [];
		scrollBarData.edge = [false, false];
		scrollBarData.reqS = [scrollBar.cfg.useHScroll, scrollBar.cfg.useVScroll];
		scrollBarData.barSpace = [0, 0];
		scrollBarData.forcedHide = [];
		scrollBarData.forcedPos = [];
		scrollBarData.paddings = [];
		ct.appendChild(scrollViewPort);
		if (extCt.getStyle('position') != 'absolute') {
			extCt.setStyle('position', 'relative');
		}
		var dAlign = extCt.getStyle('text-align');
		extCt.setStyle('textAlign', 'left');
		initScrollViewPortStyles(scrollViewPort);
		var postWidth = extCt.getWidth(),
				postHeight = extCt.getHeight(),
				mHeight;
		mHeight = scrollViewPort.offsetHeight;
		scrollViewPort.styleRef.borderBottom = "2px solid black";
		if (scrollViewPort.offsetHeight > mHeight) {
			stdMode = true;
		}
		scrollViewPort.styleRef.borderBottomWidth = "0px";
		scrollBarData.paddings[0] = extCt.getPadding('t');
		scrollBarData.paddings[2] = extCt.getPadding('l');
		scrollBarData.paddings[1] = extCt.getPadding('b');
		scrollBarData.paddings[3] = extCt.getPadding('r');
		var paddingWidthComp = scrollBarData.paddings[2] + scrollBarData.paddings[3],
				paddingHeightComp = scrollBarData.paddings[0] + scrollBarData.paddings[1];
		scrollViewPort.style.textAlign = dAlign;
		copyStyles(ct, scrollViewPort, false, ['padding-left', 'padding-right', 'padding-top', 'padding-bottom']);
		initScrollWrapperStyles();

		scrollViewPort.appendChild(contentWrapper);
		ct.appendChild(scrollWrapper);
		scrollWrapper.appendChild(zoomDetectDiv);

		contentWrapper.styleRef.position = 'absolute';
		scrollViewPort.styleRef.position = 'relative';
		contentWrapper.styleRef.top = "0";
		//contentWrapper.styleRef.width = "100%"; //fix IE7
		scrollViewPort.styleRef.overflow = 'hidden';
		scrollViewPort.styleRef.left = "-" + scrollBarData.paddings[2] + "px";
		scrollViewPort.styleRef.top = "-" + scrollBarData.paddings[0] + "px";
		scrollBarData.zTHeight = zoomDetectDiv.offsetHeight;

		scrollBarData.getContentWidth = function () {
			var contentWrapperWidth = Ext.get(contentWrapper).getWidth();
			var cChilds = contentWrapper.childNodes,
					maxCWidth = compPad = 0;
			for (var i = 0; i < cChilds.length; i++) {
				if (cChilds[i].offsetWidth) {
					maxCWidth = Math.max(cChilds[i].offsetWidth, maxCWidth)
				}
			};
			maxCWidth = Math.max(contentWrapperWidth, maxCWidth);
			scrollBarData.containerSize[0] = ((scrollBarData.reqS[1] &&
					!scrollBarData.forcedHide[1]) || scrollBarData.forcedBar[1]) ?
					ct.offsetWidth - scrollBarData.barSpace[0] : ct.offsetWidth;
			return scrollBarData.contentSize[0] = maxCWidth + paddingWidthComp;
		};

		scrollBarData.getContentHeight = function () {
			scrollBarData.containerSize[1] = ((scrollBarData.reqS[0] &&
					!scrollBarData.forcedHide[0]) || scrollBarData.forcedBar[0]) ?
					ct.offsetHeight - scrollBarData.barSpace[1] : ct.offsetHeight;
			return scrollBarData.contentSize[1] =
					contentWrapper.offsetHeight + paddingHeightComp/* - 2*/;
		};

		scrollBarData.fixIEDispBug = function () {
			contentWrapper.styleRef.display = 'none';
			contentWrapper.styleRef.display = 'block';
		};

		scrollBarData.setWidth = function () {
			scrollViewPort.styleRef.width = Math.max(0, (stdMode) ?
					(scrollBarData.containerSize[0] - paddingWidthComp - brdWidthLoss) :
					scrollBarData.containerSize[0]) + 'px';
		};

		scrollBarData.setHeight = function () {
			scrollViewPort.styleRef.height = Math.max(0, (stdMode) ?
					(scrollBarData.containerSize[1] - paddingHeightComp - brdHeightLoss) :
					scrollBarData.containerSize[1]) + 'px';
		};

		scrollBarData.createScrollBars = function () {
			scrollBarData.getContentWidth();
			scrollBarData.getContentHeight();
			// --- vertical ---
			scrollWrapper.vscroller = new Array();
			var vscroller = scrollWrapper.vscroller;
			createScrollBar(vscroller, 'vscroller');
			vscroller.barPadding = [parseInt(getStyle(vscroller.scrollerBar, 'padding-top')),
					parseInt(getStyle(vscroller.scrollerBar, 'padding-bottom'))];
			vscroller.scrollerBar.styleRef.padding = '0px';
			vscroller.scrollerBar.curPos = 0;
			vscroller.scrollerBar.vertical = true;
			vscroller.scrollerBar.indx = 1;
			contentWrapper.vBar = vscroller.scrollerBar;
			prepareScroll(vscroller, 0);
			scrollBarData.barSpace[0] = vscroller.scrollerBase.offsetWidth;
			scrollBarData.setWidth();
			// --- horizontal ---
			scrollWrapper.hscroller = new Array();
			var hscroller = scrollWrapper.hscroller;
			createScrollBar(hscroller, 'hscroller');
			hscroller.barPadding = [parseInt(getStyle(hscroller.scrollerBar, 'padding-left')),
					parseInt(getStyle(hscroller.scrollerBar, 'padding-right'))];
			hscroller.scrollerBar.styleRef.padding = '0px';
			hscroller.scrollerBar.curPos = 0;
			hscroller.scrollerBar.vertical = false;
			hscroller.scrollerBar.indx = 0;
			contentWrapper.hBar = hscroller.scrollerBar;
			prepareScroll(hscroller, 0);
			scrollBarData.barSpace[1] = hscroller.scrollerBase.offsetHeight;
			scrollBarData.setHeight();
			scrollWrapper.styleRef.height = ct.offsetHeight + 'px';
			// --- jog ---
			hscroller.jBox = createDiv('scrollerjogbox');
			scrollWrapper.appendChild(hscroller.jBox);
		};

		scrollBarData.goScroll = null;
		scrollBarData.createScrollBars();

		if (!addCheckTrigger(ct, 'mousewheel', mWheelProc) || !addCheckTrigger(ct, 'DOMMouseScroll', mWheelProc)) {
			ct.onmousewheel = mWheelProc;
		};
		addCheckTrigger(ct, 'mousewheel', mWheelProc);
		addCheckTrigger(ct, 'DOMMouseScroll', mWheelProc);
		ct.setAttribute('tabIndex', '0');

		addTrigger(ct, 'keyup', function () {
			scrollBarData.pkeY = false
		});

		addTrigger(doc, 'mouseup', intClear);
		addTrigger(ct, 'mousedown', function (e) {
			if (!e) e = wD.event;
			var cTrgt = (e.target) ? e.target : (e.srcElement) ? e.srcElement : false;
			if (!cTrgt || (cTrgt.className && cTrgt.className.match(RegExp("\\bscrollgeneric\\b")))) return;
			scrollBarData.inMposX = e.clientX;
			scrollBarData.inMposY = e.clientY;
			pageScrolled();
			findPos(ct);
			intClear();
			addTrigger(doc, 'mousemove', tSelectMouse);
			scrollBarData.mTBox = [ct.xPos + 10, ct.xPos + scrollBarData.containerSize[0] - 10, ct.yPos + 10, ct.yPos + scrollBarData.containerSize[1] - 10];
		});

		function tSelectMouse(e) {
			if (!e) e = wD.event;
			var mX = e.clientX, mY = e.clientY, mdX = mX + scrollBarData.xDocScrollLeft, mdY = mY + scrollBarData.yDocScrollLeft;
			scrollBarData.mOnXEdge = (mdX < scrollBarData.mTBox[0] || mdX > scrollBarData.mTBox[1]) ? 1 : 0;
			scrollBarData.mOnYEdge = (mdY < scrollBarData.mTBox[2] || mdY > scrollBarData.mTBox[3]) ? 1 : 0;
			scrollBarData.xAw = mX - scrollBarData.inMposX;
			scrollBarData.yAw = mY - scrollBarData.inMposY;
			var diffTop = scrollBarData.mTBox[2] - mdY;
			var diffBottom = mdY - scrollBarData.mTBox[3];
			var diffLeft = scrollBarData.mTBox[0] - mdX;
			var diffRight = mdX - scrollBarData.mTBox[1];
			scrollBarData.sXdir = ((diffLeft > -5) && (diffLeft < 15)) ? -1 : ((diffRight > -5) && (diffRight < 15)) ? 1 : 0;
			scrollBarData.sYdir = ((diffTop > -5) && (diffTop < 15)) ? -1 : ((diffBottom > -5) && (diffBottom < 15)) ? 1 : 0;
			if ((scrollBarData.sXdir != 0 || scrollBarData.sYdir != 0) && !scrollBarData.tSelectFunc) scrollBarData.tSelectFunc = wD.setInterval(function () {
				if (scrollBarData.sXdir == 0 && scrollBarData.sYdir == 0) {
					wD.clearInterval(scrollBarData.tSelectFunc);
					scrollBarData.tSelectFunc = false;
					return;
				};
				pageScrolled();
				if (scrollBarData.mOnXEdge == 1 || scrollBarData.mOnYEdge == 1) ct.contentScroll((scrollBarData.sXdir * scrollBarData.mOnXEdge) + "s", (scrollBarData.sYdir * scrollBarData.mOnYEdge) + "s", true);
			}, 45)
		};

		function intClear() {
			removeTrigger(doc, 'mousemove', tSelectMouse);
			if (scrollBarData.tSelectFunc) wD.clearInterval(scrollBarData.tSelectFunc);
			scrollBarData.tSelectFunc = false;
			if (scrollBarData.barClickRetard) wD.clearTimeout(scrollBarData.barClickRetard);
			if (scrollBarData.barClickScroll) wD.clearInterval(scrollBarData.barClickScroll);
		};

		function pageScrolled() {
			scrollBarData.xDocScrollLeft = (wD.pageXOffset) ? wD.pageXOffset :
					(doc.documentElement && doc.documentElement.scrollLeft) ? doc.documentElement.scrollLeft : 0;
			scrollBarData.yDocScrollLeft = (wD.pageYOffset) ? wD.pageYOffset :
					(doc.documentElement && doc.documentElement.scrollTop) ? doc.documentElement.scrollTop : 0;
		};

		scrollBar.innerUpdate = function (recurse) {
			scrollWrapper.fShow();
			//if (scrollWrapper.getSize[1]() === 0 || scrollWrapper.getSize[0]() === 0) return;
			//contentWrapper.styleRef.padding = '1px';
			var reqH = scrollBarData.reqS[0],
					reqV = scrollBarData.reqS[1],
					vBr = scrollWrapper.vscroller,
					hBr = scrollWrapper.hscroller,
					vUpReq, hUpReq, cPSize = [];
			var scrollWrapperWidth = ct.offsetWidth - brdWidthLoss;
			scrollWrapperWidth = (scrollWrapperWidth > 0) ? scrollWrapperWidth : 0;
			var scrollWrapperHeight = ct.offsetHeight - brdHeightLoss;
			scrollWrapperHeight = (scrollWrapperHeight > 0) ? scrollWrapperHeight : 0;
			scrollWrapper.styleRef.width = Ext.Element.addUnits(scrollWrapperWidth);
			scrollWrapper.styleRef.height =
					Ext.Element.addUnits(scrollWrapperHeight);
			cPSize[0] = scrollBarData.containerSize[0];
			cPSize[1] = scrollBarData.containerSize[1];
			scrollBarData.reqS[0] = scrollBarData.getContentWidth() >
					scrollBarData.containerSize[0] && scrollBar.cfg.useHScroll;
			scrollBarData.reqS[1] = scrollBarData.getContentHeight() >
					scrollBarData.containerSize[1] && scrollBar.cfg.useVScroll;
			var stateChange = (reqH != scrollBarData.reqS[0] || reqV != scrollBarData.reqS[1] ||
					cPSize[0] != scrollBarData.containerSize[0] || cPSize[1] !=
					scrollBarData.containerSize[1]) ? true : false;
			vBr.scrollerBase.setVisibility(scrollBarData.reqS[1]);
			hBr.scrollerBase.setVisibility(scrollBarData.reqS[0]);
			var hasBottomIndent = (this.cfg.indentBottom && this.cfg.indentBottom != "0");
			vUpReq = (scrollBarData.reqS[1] || scrollBarData.forcedBar[1]);
			hUpReq = (scrollBarData.reqS[0] || scrollBarData.forcedBar[0]);
			scrollBarData.getContentWidth();
			scrollBarData.getContentHeight();
			scrollBarData.setHeight();
			scrollBarData.setWidth();
			if (((!scrollBarData.reqS[0] || !scrollBarData.reqS[1] ||
					scrollBarData.forcedHide[0] || scrollBarData.forcedHide[1]) && (!(hasBottomIndent && vUpReq))) ||
					(hasBottomIndent && hUpReq)) {
				hBr.jBox.fHide();
			} else {
				hBr.jBox.style.height = (hasBottomIndent ? this.cfg.indentBottom : scrollBarData.barSpace[1]) + 'px';
				hBr.jBox.fShow();
			}
			if (vUpReq) {
				var jogHeight = (hUpReq && !scrollBarData.forcedHide[0]) ? scrollBarData.barSpace[1] : 0;
				if (hasBottomIndent) {
					jogHeight += this.cfg.indentBottom;
				}
				updateScroll(vBr, jogHeight);
			} else {
				contentWrapper.styleRef.top = "0";
			}
			if (hUpReq) {
				updateScroll(hBr, (vUpReq && !scrollBarData.forcedHide[1] && !hasBottomIndent) ?
						scrollBarData.barSpace[0] : 0);
			} else {
				contentWrapper.styleRef.left = "0";
			}
			if (stateChange && !recurse) {
				this.innerUpdate(true);
			}
			scrollBarData.edge[0] = scrollBarData.edge[1] = false;
		};

		scrollBar.applyConfig = function (config) {
			this.cfg = Ext.apply(this.cfg, config);
			var contentWrapper = this.contentWrap;
			if (this.cfg.indentBottom != undefined && contentWrapper) {
				contentWrapper.applyStyles({ paddingBottom: contentWrapper.addUnits(this.cfg.indentBottom) });
			}
		};

		scrollBar.update = function (config) {
			var contentWrapper = this.contentWrap;
			if (contentWrapper) {
				contentWrapperStyle = contentWrapper.dom.style;
				var height = contentWrapperStyle.height;
				if (height == "100%") {
					contentWrapperStyle.height = "";
				}
				var width = contentWrapperStyle.width;
				if (width == "100%") {
					contentWrapperStyle.width = "";
				}
			}
			this.applyConfig(config);
			this.innerUpdate();
			if ((contentWrapperStyle.height == "") && !this.vScroll.isVisible()) {
				contentWrapperStyle.height = "100%";
			}
			if ((contentWrapperStyle.width == "") && !this.hScroll.isVisible()) {
				contentWrapperStyle.width = "100%";
			}
		};

		ct.contentScroll = function (xPos, yPos, relative) {
			var reT = [[false, false], [false, false]], Bar;
			if ((xPos || xPos === 0) && scrollBarData.scroller[0]) {
				xPos = calcCScrollVal(xPos, 0);
				Bar = scrollWrapper.hscroller.scrollerBar;
				Bar.trgtScrll = (relative) ? Math.min(Math.max(Bar.mxScroll, Bar.trgtScrll - xPos), 0) : -xPos;
				Bar.contentScrollPos();
				reT[0] = [-Bar.trgtScrll - Bar.targetSkew, -Bar.mxScroll]
			}
			if ((yPos || yPos === 0) && scrollBarData.scroller[1]) {
				yPos = calcCScrollVal(yPos, 1);
				Bar = scrollWrapper.vscroller.scrollerBar;
				Bar.trgtScrll = (relative) ? Math.min(Math.max(Bar.mxScroll, Bar.trgtScrll - yPos), 0) : -yPos;
				Bar.contentScrollPos();
				reT[1] = [-Bar.trgtScrll - Bar.targetSkew, -Bar.mxScroll]
			}
			if (!relative) {
				scrollBarData.edge[0] = scrollBarData.edge[1] = false;
			}
			return reT;
		};

		ct.needToScrollElement = function (el) {
			var ctRect = ct.getBoundingClientRect();
			var elRect = el.getBoundingClientRect();
			var result = false;
			if ((elRect.left < ctRect.left) || (elRect.right > ctRect.right) ||
					(elRect.top < ctRect.top) || (elRect.bottom > ctRect.bottom)) {
				result = true;
			}
			return result;
		};

		ct.scrollToElement = function (tEM, checkNeedToScroll) {
			if (tEM == null || !isddvChild(tEM) || (checkNeedToScroll !== false && !ct.needToScrollElement(tEM))) {
				return;
			}
			var sPos = findRCpos(tEM);
			ct.contentScroll(sPos[0] + scrollBarData.paddings[2], sPos[1] + scrollBarData.paddings[0], false);
			ct.contentScroll(0, 0, true);
		};

		ct.scrollTop = 0; ct.scrollLeft = 0;
		ct.fleXcroll = true;
		classChange(ct, 'scroll-active', false);
		scrollBar.innerUpdate();
		ct.contentScroll(oScrollX, oScrollY, true);
		if (urlBase.match(uReg)) {
			ct.scrollToElement(doc.getElementById(urlBase.match(uReg)[1]));
		};
		//scrollWrapper.fShow();

		scrollBarData.sizeChangeDetect = wD.setInterval(function () {
			var n = zoomDetectDiv.offsetHeight;
			if (n != scrollBarData.zTHeight) {
				scrollBar.innerUpdate();
				scrollBarData.zTHeight = n
			};
		}, 2500);

		function calcCScrollVal(v, i) {
			var stR = v.toString();
			v = parseFloat(stR);
			return parseInt((stR.match(/p$/)) ? v * scrollBarData.containerSize[i] * 0.9 :
					(stR.match(/s$/)) ? v * scrollBarData.containerSize[i] * 0.1 : v);
		}

		function camelConv(spL) {
			var spL = spL.split('-'),
					reT = spL[0], i;
			for (i = 1; parT = spL[i]; i++) {
				reT += parT.charAt(0).toUpperCase() + parT.substr(1);
			}
			return reT;
		}

		// TODO убрать после полного перевода на ExtJs
		function getStyle(elem, style) {
			return Ext.get(elem).getStyle(style);
		}

		function copyStyles(src, dest, replaceStr, sList) {
			src = Ext.get(src);
			dest = Ext.get(dest);
			for (var i = 0; i < sList.length; i++) {
				dest.setStyle(sList[i], src.getStyle(sList[i]));
				if (replaceStr) {
					src.setStyle(sList[i], replaceStr);
				}
			}
		};

		function divOffsetWidth(div) {
			return div.offsetWidth;
		}

		function divOffsetHeight(div) {
			return div.offsetHeight;
		}

		function divWidth(div, sVal) {
			div.styleRef.width =
					(sVal.indexOf('-') == -1 && sVal.indexOf('NaN') == -1) ? sVal : "0";
		}

		function divHeight(div, sVal) {
			div.styleRef.height =
					(sVal.indexOf('-') == -1 && sVal.indexOf('NaN') == -1) ? sVal : "0";
		}

		function divLeft(div) {
			return getStyle(div, "left");
		}

		function divTop(div) {
			return getStyle(div, "top");
		}

		function setDivLeft(div, sVal) {
			div.styleRef.left = (sVal.indexOf('NaN') == -1) ? sVal : "0";
		}

		function setDivTop(div, sVal) {
			div.styleRef.top = (sVal.indexOf('NaN') == -1) ? sVal : "0";
		}

		function fHide() {
			this.styleRef.visibility = "hidden";
		}

		function fShow(coPy) {
			this.styleRef.visibility = (coPy) ? (getStyle(coPy, 'visibility') || "inherit") : "visible";
		}

		function createDiv(typeName, noGenericClass) {
			var newDiv = doc.createElement('div');
			newDiv.id = targetId + '_' + typeName;
			newDiv.className = (noGenericClass) ? typeName : typeName + ' scrollgeneric';
			newDiv.getSize = [
					divOffsetWidth,
					divOffsetHeight
				];
			newDiv.setSize = [
					divWidth,
					divHeight
				];
			newDiv.getPos = [
					divLeft,
					divTop
				];
			newDiv.setPos = [
					setDivLeft,
					setDivTop
				];
			newDiv.fHide = fHide;
			newDiv.fShow = fShow;
			newDiv.styleRef = newDiv.style;
			//	if(!noGenericClass) newDiv.appendChild(pTx);
			return newDiv;
		};

		function createScrollBar(ary, bse) {
			ary.scrollerBase = createDiv(bse + 'base');
			ary.scrollerBaseBeg = createDiv(bse + 'basebeg');
			ary.scrollerBaseEnd = createDiv(bse + 'baseend');
			ary.scrollerBar = createDiv(bse + 'bar');
			scrollWrapper.appendChild(ary.scrollerBase);
			ary.scrollerBase.appendChild(ary.scrollerBar);
			ary.scrollerBase.appendChild(ary.scrollerBaseBeg);
			ary.scrollerBase.appendChild(ary.scrollerBaseEnd);
		};

		function prepareScroll(bAr, reqSpace) {
			var scrollerBase = bAr.scrollerBase,
					scrollerBar = bAr.scrollerBar,
					i = scrollerBar.indx;
			scrollerBar.minPos = bAr.barPadding[0];
			scrollerBar.ofstParent = scrollerBase;
			scrollerBar.scrollViewPort = scrollViewPort;
			scrollerBar.scrollTarget = contentWrapper;
			scrollerBar.targetSkew = 0;
			updateScroll(bAr, reqSpace, true);

			scrollerBar.doScrollPos = function () {
				scrollerBar.curPos = (Math.min(Math.max(scrollerBar.curPos, 0), scrollerBar.maxPos));
				scrollerBar.trgtScrll = parseInt((scrollerBar.curPos / scrollerBar.sRange) * scrollerBar.mxScroll);
				scrollerBar.targetSkew = (scrollerBar.curPos == 0) ? 0 : (scrollerBar.curPos == scrollerBar.maxPos) ? 0 : scrollerBar.targetSkew;
				scrollerBar.setPos[i](scrollerBar, scrollerBar.curPos + scrollerBar.minPos + "px");
				contentWrapper.setPos[i](contentWrapper, scrollerBar.trgtScrll + scrollerBar.targetSkew + "px");
				if (scrollBar.cfg.onScroll) {
					scrollBar.cfg.onScroll(contentWrapper.getPos[0](contentWrapper), contentWrapper.getPos[1](contentWrapper));
				}
			};

			scrollerBar.contentScrollPos = function () {
				scrollerBar.curPos = parseInt((scrollerBar.trgtScrll * scrollerBar.sRange) / scrollerBar.mxScroll);
				scrollerBar.targetSkew = scrollerBar.trgtScrll - parseInt((scrollerBar.curPos / scrollerBar.sRange) * scrollerBar.mxScroll);
				scrollerBar.curPos = (Math.min(Math.max(scrollerBar.curPos, 0), scrollerBar.maxPos));
				scrollerBar.setPos[i](scrollerBar, scrollerBar.curPos + scrollerBar.minPos + "px");
				contentWrapper.setPos[i](contentWrapper, scrollerBar.trgtScrll + "px")
				if (scrollBar.cfg.onScroll) {
					scrollBar.cfg.onScroll(contentWrapper.getPos[0](contentWrapper), contentWrapper.getPos[1](contentWrapper));
				}
			};

			scrollBarData.barZ = getStyle(scrollerBar, 'z-index');
			scrollerBar.styleRef.zIndex = (scrollBarData.barZ == "auto" || scrollBarData.barZ == "0" || scrollBarData.barZ == 'normal') ? 2 : scrollBarData.barZ;
			scrollViewPort.styleRef.zIndex = getStyle(scrollerBar, 'z-index');

			scrollerBar.onmousedown = function () {
				scrollerBar.clicked = true;
				scrollBarData.goScroll = scrollerBar;
				scrollerBar.scrollBoth = false;
				scrollerBar.moved = false;
				addTrigger(doc, 'selectstart', retFalse);
				addTrigger(doc, 'mousemove', mMoveBar);
				addTrigger(doc, 'mouseup', mMouseUp);
				return false;
			};

			scrollerBar.onmouseover = intClear;

			scrollerBase.onmousedown = scrollerBase.ondblclick = function (e) {
				if (!e) {
					var e = wD.event;
				}
				if (e.target && (e.target == bAr.scrollerBar)) return;
				if (e.srcElement && (e.srcElement == bAr.scrollerBar)) return;
				var relPos, mV = [];
				pageScrolled();
				scrollBarData.mDPosFix();
				findPos(scrollerBar);
				relPos = (scrollerBar.vertical) ? e.clientY + scrollBarData.yDocScrollLeft - scrollerBar.yPos : e.clientX + scrollBarData.xDocScrollLeft - scrollerBar.xPos;
				mV[scrollerBar.indx] = (relPos < 0) ? scrollBarData.baseAct[0] : scrollBarData.baseAct[1];
				mV[1 - scrollerBar.indx] = 0;
				ct.contentScroll(mV[0], mV[1], true);
				if (e.type != "dblclick") {
					intClear();
					scrollBarData.barClickRetard = wD.setTimeout(function () {
						scrollBarData.barClickScroll = wD.setInterval(function () {
							ct.contentScroll(mV[0], mV[1], true);
						}, 80)
					}, 425);
				}
				return false;
			};

			scrollerBase.setVisibility = function (r) {
				//r = r || scrollerBar.indx == 1;
				if (r) {
					scrollerBase.fShow(ct);
					scrollBarData.forcedHide[i] = (getStyle(scrollerBase, "visibility") == "hidden") ? true : false;
					if (!scrollBarData.forcedHide[i]) {
						scrollerBar.fShow(ct);
					} else {
						scrollerBar.fHide();
					}
					scrollBarData.scroller[i] = true;
					classChange(scrollerBase, "", "scroll-inactive");
				} else {
					scrollerBase.fHide();
					scrollerBar.fHide();
					scrollBarData.forcedBar[i] = (getStyle(scrollerBase, "visibility") != "hidden") ? true : false;
					scrollBarData.scroller[i] = false;
					scrollerBar.curPos = 0;
					contentWrapper.setPos[i](contentWrapper, '0px');
					classChange(scrollerBase, "scroll-inactive", "");
				}
				scrollViewPort.setPos[1 - i](scrollViewPort, (scrollBarData.forcedPos[i] && (r || scrollBarData.forcedBar[i]) && !scrollBarData.forcedHide[i]) ?
						scrollBarData.barSpace[1 - i] - scrollBarData.paddings[i * 2] + "px" :
						"-" + scrollBarData.paddings[i * 2] + "px");
			};

			scrollerBase.onmouseclick = retFalse;

		};

		function updateScroll(bAr, reqSpace, firstRun) {
			var scrollerBase = bAr.scrollerBase,
					scrollerBar = bAr.scrollerBar,
					scrollerBaseBeg = bAr.scrollerBaseBeg,
					scrollerBaseEnd = bAr.scrollerBaseEnd,
					i = scrollerBar.indx;
			scrollerBase.setSize[i](scrollerBase, scrollWrapper.getSize[i](scrollWrapper) - reqSpace + 'px');
			scrollerBase.setPos[1 - i](scrollerBase, scrollWrapper.getSize[1 - i](scrollWrapper) - scrollerBase.getSize[1 - i](scrollerBase) + 'px');
			scrollBarData.forcedPos[i] = (parseInt(scrollerBase.getPos[1 - i](scrollerBase)) === 0) ? true : false;
			bAr.padLoss = bAr.barPadding[0] + bAr.barPadding[1];
			bAr.baseProp =
					Math.max(parseInt((scrollerBase.getSize[i](scrollerBase) - bAr.padLoss) * 0.75), 0);
			var propMinSize = Math.min(parseInt(scrollBarData.containerSize[i] /
					scrollBarData.contentSize[i] * scrollerBase.getSize[i](scrollerBase)), bAr.baseProp);
			scrollerBar.aSize = Math.min(Math.max(propMinSize, 45), bAr.baseProp);
			scrollerBar.setSize[i](scrollerBar, scrollerBar.aSize + 'px');
			scrollerBar.maxPos = scrollerBase.getSize[i](scrollerBase) - scrollerBar.getSize[i](scrollerBar) - bAr.padLoss;
			scrollerBar.curPos = Math.min(Math.max(0, scrollerBar.curPos), scrollerBar.maxPos);
			scrollerBar.setPos[i](scrollerBar, scrollerBar.curPos + scrollerBar.minPos + 'px');
			scrollerBar.mxScroll = scrollViewPort.getSize[i](scrollViewPort) - scrollBarData.contentSize[i];
			scrollerBar.sRange = scrollerBar.maxPos;
			scrollerBaseBeg.setSize[i](scrollerBaseBeg, Math.max(scrollerBase.getSize[i](scrollerBase) -
					scrollerBaseEnd.getSize[i](scrollerBaseEnd), 0) + 'px');
			scrollerBaseEnd.setPos[i](scrollerBaseEnd, scrollerBase.getSize[i](scrollerBase) -
					scrollerBaseEnd.getSize[i](scrollerBaseEnd) + 'px');
			if (!firstRun) {
				scrollerBar.doScrollPos();
			}
			scrollBarData.fixIEDispBug();
		};

		scrollBarData.mDPosFix = function () {
			scrollViewPort.scrollTop = 0;
			scrollViewPort.scrollLeft = 0;
			ct.scrollTop = 0;
			ct.scrollLeft = 0;
		};

		addTrigger(wD, 'load', function () {
			if (ct.fleXcroll) {
				scrollBar.innerUpdate();
			}
		});

		addTrigger(wD, 'resize', function () {
			if (ct.refreshTimeout) {
				wD.clearTimeout(ct.refreshTimeout);
			}
			ct.refreshTimeout = wD.setTimeout(function () {
				if (ct.fleXcroll) {
					scrollBar.innerUpdate();
				}
			}, 80);
		});

		for (var j = 0, inputName; inputName = focusProtectList[j]; j++) {
			var inputList = ct.getElementsByTagName(inputName);
			for (var i = 0, formItem; formItem = inputList[i]; i++) {
				addTrigger(formItem, 'focus', function () {
					ct.focusProtect = true;
				});
				addTrigger(formItem, 'blur', onblur = function () {
					ct.focusProtect = false;
				});
			}
		};

		function retFalse() {
			return false;
		};

		function mMoveBar(e) {
			if (!e) {
				var e = wD.event;
			};
			var FCBar = scrollBarData.goScroll,
					movBr, maxx, xScroll, yScroll;
			if (FCBar == null) return;
			if (!w3events && !e.button) {
				mMouseUp();
			}
			maxx = (FCBar.scrollBoth) ? 2 : 1;
			for (var i = 0; i < maxx; i++) {
				movBr = (i == 1) ? FCBar.scrollTarget.vBar : FCBar;
				if (FCBar.clicked) {
					if (!movBr.moved) {
						scrollBarData.mDPosFix();
						findPos(movBr);
						findPos(movBr.ofstParent);
						movBr.pointerOffsetY = e.clientY - movBr.yPos;
						movBr.pointerOffsetX = e.clientX - movBr.xPos;
						movBr.inCurPos = movBr.curPos;
						movBr.moved = true;
					};
					movBr.curPos = (movBr.vertical) ? e.clientY - movBr.pointerOffsetY - movBr.ofstParent.yPos - movBr.minPos :
							e.clientX - movBr.pointerOffsetX - movBr.ofstParent.xPos - movBr.minPos;
					if (FCBar.scrollBoth) {
						movBr.curPos = movBr.curPos + (movBr.curPos - movBr.inCurPos);
					}
					movBr.doScrollPos();
				} else {
					movBr.moved = false;
				}
			};
		};

		function mMouseUp() {
			if (scrollBarData.goScroll != null) {
				scrollBarData.goScroll.clicked = false;
			}
			scrollBarData.goScroll = null;
			removeTrigger(doc, 'selectstart', retFalse);
			removeTrigger(doc, 'mousemove', mMoveBar);
			removeTrigger(doc, 'mouseup', mMouseUp);
		};

		function mWheelProc(e) {
			if (!e) e = wD.event;
			if (!this.fleXcroll) return;
			var scrDv = this, vEdge, hEdge,
					hoverH = false, delta = 0, iNDx;
			scrollBarData.mDPosFix();
			hElem = (e.target) ? e.target : (e.srcElement) ? e.srcElement : this;
			if (hElem.id && hElem.id.match(/_hscroller/)) hoverH = true;
			if (e.wheelDelta) delta = -e.wheelDelta;
			if (e.detail) delta = e.detail;
			delta = (delta < 0) ? -1 : +1;
			iNDx = (delta < 0) ? 0 : 1;
			scrollBarData.edge[1 - iNDx] = false;
			if ((scrollBarData.edge[iNDx] && !hoverH) || (!scrollBarData.scroller[0] && !scrollBarData.scroller[1])) return;
			if (scrollBarData.scroller[1] && !hoverH)
				scrollState = ct.contentScroll(false, scrollBarData.wheelAct[iNDx], true);
			vEdge = !scrollBarData.scroller[1] || hoverH || (scrollBarData.scroller[1] && ((scrollState[1][0] == scrollState[1][1] && delta > 0) || (scrollState[1][0] == 0 && delta < 0)));
			if (scrollBarData.scroller[0] && (!scrollBarData.scroller[1] || hoverH))
				scrollState = ct.contentScroll(scrollBarData.wheelAct[iNDx], false, true);
			hEdge = !scrollBarData.scroller[0] || (scrollBarData.scroller[0] && scrollBarData.scroller[1] && vEdge && !hoverH) || (scrollBarData.scroller[0] && ((scrollState[0][0] == scrollState[0][1] && delta > 0) || (scrollState[0][0] == 0 && delta < 0)));
			scrollBarData.edge[iNDx] = (vEdge && hEdge && !hoverH) ? true : false;
			/* if (vEdge && hEdge && !hoverH) {scrollBarData.edge[iNDx] = true;} else {scrollBarData.edge[iNDx] = false}; */
			if (e.preventDefault) e.preventDefault();
			return false;
		};

		function isddvChild(elem) {
			while (elem.parentNode) {
				elem = elem.parentNode;
				if (elem == ct) return true;
			}
			return false;
		};

		function findPos(elem) {
			var xy = Ext.get(elem).getXY();
			elem.xPos = xy[0];
			elem.yPos = xy[1];
		};

		function findRCpos(elem) {
			var obj = elem;
			curleft = curtop = 0;
			while (!obj.offsetHeight && obj.parentNode && obj != contentWrapper && getStyle(obj, 'display') == "inline") {
				obj = obj.parentNode;
			}
			if (obj.offsetParent) {
				while (obj != contentWrapper) {
					curleft += obj.offsetLeft;
					curtop += obj.offsetTop;
					obj = obj.offsetParent;
				}
			}
			return [curleft, curtop];
		};

		function classChange(elem, addClass, remClass) {
			var extElem = Ext.get(elem);
			extElem.addClass(addClass);
			extElem.removeClass(remClass);
		};

		scrollBar.contentWrap = Ext.get(contentWrapper);
		scrollBar.vScroll = Ext.get(scrollWrapper.vscroller.scrollerBase);
		scrollBar.hScroll = Ext.get(scrollWrapper.hscroller.scrollerBase);
		scrollBar.getVScrollWidth = function () {
			return this.vScroll.isVisible() ? scrollBar.vScroll.getWidth() : 0;
		}
		scrollBar.getVScrollHeight = function () {
			return this.vScroll.isVisible() ? scrollBar.vScroll.getHeight() : 0;
		}
		scrollBar.getHScrollWidth = function () {
			return this.hScroll.isVisible() ? scrollBar.hScroll.getWidth() : 0;
		}
		scrollBar.getHScrollHeight = function () {
			return this.hScroll.isVisible() ? scrollBar.hScroll.getHeight() : 0;
		}

		return scrollBar;

	};
	// --- initScrollBar code end ---

	var globalInit = function () {
		var regg = /#([^#.]*)$/,
				urlExt = /(.*)#.*$/, matcH, i, anchoR,
				anchorList = document.getElementsByTagName("a"),
				urlBase = document.location.href;
		if (urlBase.match(urlExt)) {
			urlBase = urlBase.match(urlExt)[1];
		}
		for (i = 0; anchoR = anchorList[i]; i++) {
			if (anchoR.href && anchoR.href.match(regg) && anchoR.href.match(urlExt) && urlBase === anchoR.href.match(urlExt)[1]) {
				anchoR.fleXanchor = true;
				addTrigger(anchoR, 'click', function (e) {
					if (!e) e = window.event;
					var clickeD = (e.srcElement) ? e.srcElement : this;
					while (!clickeD.fleXanchor && clickeD.parentNode) {
						clickeD = clickeD.parentNode
					};
					if (!clickeD.fleXanchor) return;
					var tEL = document.getElementById(clickeD.href.match(regg)[1]), eScroll = false;
					if (tEL == null) {
						tEL = (tEL = document.getElementsByName(clickeD.href.match(regg)[1])[0]) ? tEL : null;
					}
					if (tEL != null) {
						var elem = tEL;
						while (elem.parentNode) {
							elem = elem.parentNode;
							if (elem.scrollToElement) {
								elem.scrollToElement(tEL);
								eScroll = elem;
							};
						};
						if (eScroll) {
							if (e.preventDefault) {
								e.preventDefault();
							}
							document.location.href = "#" + clickeD.href.match(regg)[1];
							eScroll.scrollBarData.mDPosFix();
							return false;
						}
					};
				});
			};
		};
		if (window.onfleXcrollRun) {
			window.onfleXcrollRun();
		}
	};

	var mons = [];

	var unregisterEvents = function () {
		var i;
		for (i = 0; i < mons.length; i++) {
			removeTrigger(mons[i].element, mons[i].event, mons[i].handler);
		}
		if (Ext.isIE) {
			window.detachEvent("onunload", unregisterEvents);
		} else {
			window.removeEventListener("unload", unregisterEvents, false);
		}
		mons = null;
	};

	if (Ext.isIE) {
		window.attachEvent("onunload", unregisterEvents);
	} else {
		window.addEventListener("unload", unregisterEvents, false);
	}

	var addTrigger = function (elm, eventname, func) {
		if (!addCheckTrigger(elm, eventname, func) && elm.attachEvent) {
			elm.attachEvent('on' + eventname, func);
			mons.push({
				element: elm,
				event: eventname,
				handler: func
			});
		}
	};

	var addCheckTrigger = function (elm, eventname, func) {
		if (elm.addEventListener) {
			elm.addEventListener(eventname, func, false);
			w3events = true;
			mons.push({
				element: elm,
				event: eventname,
				handler: func
			});
			return true;
		} else
			return false;
	};

	var removeTrigger = function (elm, eventname, func) {
		if (!removeCheckTrigger(elm, eventname, func) && elm.detachEvent) {
			elm.detachEvent('on' + eventname, func);
		}
	};

	var removeCheckTrigger = function (elm, eventname, func) {
		if (elm.removeEventListener) {
			elm.removeEventListener(eventname, func, false);
			return true;
		} else
			return false;
	}

	globalInit();

	return {

		insertScrollBar: function (ct, cfg) {
			return initScrollBar(ct, cfg);
		}

	};

} ();

Ext.data.SortTypes = {
	none: function (s) {
		return s;
	},

	stripTagsRE: /<\/?[^>]+>/gi,

	asText: function (s) {
		return String(s).replace(this.stripTagsRE, "");
	},

	asUCText: function (s) {
		return String(s).toUpperCase().replace(this.stripTagsRE, "");
	},

	asUCString: function (s) {
		return String(s).toUpperCase();
	},

	asDate: function (s) {
		if (!s) {
			return 0;
		}
		if (Ext.isDate(s)) {
			return s.getTime();
		}
		return Date.parse(String(s));
	},

	asFloat: function (s) {
		var val = parseFloat(String(s).replace(/,/g, ""));
		if (isNaN(val)) val = 0;
		return val;
	},

	asInt: function (s) {
		var val = parseInt(String(s).replace(/,/g, ""));
		if (isNaN(val)) val = 0;
		return val;
	}
};

Ext.data.Record = function (data, id) {
	this.id = (id || id === 0) ? id : ++Ext.data.Record.AUTO_ID;
	this.data = data;
};

Ext.data.Record.create = function (o) {
	var f = Ext.extend(Ext.data.Record, {});
	var p = f.prototype;
	p.fields = new Ext.util.MixedCollection(false, function (field) {
		return field.name;
	});
	for (var i = 0, len = o.length; i < len; i++) {
		p.fields.add(new Ext.data.Field(o[i]));
	}
	f.getField = function (name) {
		return p.fields.get(name);
	};
	return f;
};

Ext.data.Record.AUTO_ID = 1000;
Ext.data.Record.EDIT = 'edit';
Ext.data.Record.REJECT = 'reject';
Ext.data.Record.COMMIT = 'commit';

Ext.data.Record.prototype = {
	dirty: false,
	editing: false,
	error: null,
	modified: null,

	join: function (store) {
		this.store = store;
	},

	set: function (name, value) {
		if (String(this.data[name]) == String(value)) {
			return;
		}
		this.dirty = true;
		if (!this.modified) {
			this.modified = {};
		}
		if (typeof this.modified[name] == 'undefined') {
			this.modified[name] = this.data[name];
		}
		this.data[name] = value;
		if (!this.editing && this.store) {
			this.store.afterEdit(this);
		}
	},

	get: function (name) {
		return this.data[name];
	},

	beginEdit: function () {
		this.editing = true;
		this.modified = {};
	},

	cancelEdit: function () {
		this.editing = false;
		delete this.modified;
	},

	endEdit: function () {
		this.editing = false;
		if (this.dirty && this.store) {
			this.store.afterEdit(this);
		}
	},

	reject: function (silent) {
		var m = this.modified;
		for (var n in m) {
			if (typeof m[n] != "function") {
				this.data[n] = m[n];
			}
		}
		this.dirty = false;
		delete this.modified;
		this.editing = false;
		if (this.store && silent !== true) {
			this.store.afterReject(this);
		}
	},

	commit: function (silent) {
		this.dirty = false;
		delete this.modified;
		this.editing = false;
		if (this.store && silent !== true) {
			this.store.afterCommit(this);
		}
	},

	getChanges: function () {
		var m = this.modified, cs = {};
		for (var n in m) {
			if (m.hasOwnProperty(n)) {
				cs[n] = this.data[n];
			}
		}
		return cs;
	},

	hasError: function () {
		return this.error != null;
	},

	clearError: function () {
		this.error = null;
	},

	copy: function (newId) {
		return new this.constructor(Ext.apply({}, this.data), newId || this.id);
	},

	isModified: function (fieldName) {
		return !!(this.modified && this.modified.hasOwnProperty(fieldName));
	}
};

Ext.StoreMgr = Ext.apply(new Ext.util.MixedCollection(), {

	register: function () {
		for (var i = 0, s; s = arguments[i]; i++) {
			this.add(s);
		}
	},

	unregister: function () {
		for (var i = 0, s; s = arguments[i]; i++) {
			this.remove(this.lookup(s));
		}
	},

	lookup: function (id) {
		return typeof id == "object" ? id : this.get(id);
	},

	getKey: function (o) {
		return o.storeId || o.id;
	}
});

Ext.data.Store = function (config) {
	this.data = new Ext.util.MixedCollection(false);
	this.data.getKey = function (o) {
		return o.id;
	};

	this.baseParams = {};
	this.paramNames = {
		"start": "start",
		"limit": "limit",
		"sort": "sort",
		"dir": "dir"
	};

	if (config && config.data) {
		this.inlineData = config.data;
		delete config.data;
	}

	Ext.apply(this, config);

	if (this.url && !this.proxy) {
		this.proxy = new Ext.data.HttpProxy({ url: this.url });
	}

	if (this.reader) {
		if (!this.recordType) {
			this.recordType = this.reader.recordType;
		}
		if (this.reader.onMetaChange) {
			this.reader.onMetaChange = this.onMetaChange.createDelegate(this);
		}
	}

	if (this.recordType) {
		this.fields = this.recordType.prototype.fields;
	}
	this.modified = [];

	this.addEvents(
			'datachanged',
			'metachange',
			'add',
			'remove',
			'update',
			'clear',
			'beforeload',
			'load',
			'loadexception'
    );

	if (this.proxy) {
		this.relayEvents(this.proxy, ["loadexception"]);
	}

	this.sortToggle = {};
	if (this.sortInfo) {
		this.setDefaultSort(this.sortInfo.field, this.sortInfo.direction);
	}

	Ext.data.Store.superclass.constructor.call(this);

	if (this.storeId || this.id) {
		Ext.StoreMgr.register(this);
	}
	if (this.inlineData) {
		this.loadData(this.inlineData);
		delete this.inlineData;
	} else if (this.autoLoad) {
		this.load.defer(10, this, [
            typeof this.autoLoad == 'object' ?
                this.autoLoad : undefined]);
	}
};

Ext.extend(Ext.data.Store, Ext.util.Observable, {
	remoteSort: false,
	pruneModifiedRecords: false,
	lastOptions: null,

	destroy: function () {
		if (this.id) {
			Ext.StoreMgr.unregister(this);
		}
		this.data = null;
		this.purgeListeners();
	},

	add: function (records) {
		records = [].concat(records);
		if (records.length < 1) {
			return;
		}
		for (var i = 0, len = records.length; i < len; i++) {
			records[i].join(this);
		}
		var index = this.data.length;
		this.data.addAll(records);
		if (this.snapshot) {
			this.snapshot.addAll(records);
		}
		this.fireEvent("add", this, records, index);
	},

	addSorted: function (record) {
		var index = this.findInsertIndex(record);
		this.insert(index, record);
	},

	remove: function (record) {
		if (!record) {
			return;
		}
		var index = this.data.indexOf(record);
		this.data.removeAt(index);
		if (this.pruneModifiedRecords) {
			this.modified.remove(record);
		}
		if (this.snapshot) {
			this.snapshot.remove(record);
		}
		this.fireEvent("remove", this, record, index);
	},

	removeAll: function () {
		this.data.clear();
		if (this.snapshot) {
			this.snapshot.clear();
		}
		if (this.pruneModifiedRecords) {
			this.modified = [];
		}
		this.fireEvent("clear", this);
	},

	insert: function (index, records) {
		records = [].concat(records);
		for (var i = 0, len = records.length; i < len; i++) {
			this.data.insert(index, records[i]);
			records[i].join(this);
		}
		this.fireEvent("add", this, records, index);
	},

	indexOf: function (record) {
		return this.data.indexOf(record);
	},

	indexOfId: function (id) {
		return this.data.indexOfKey(id);
	},

	getById: function (id) {
		return this.data.key(id);
	},

	getAt: function (index) {
		return this.data.itemAt(index);
	},

	getRange: function (start, end) {
		return this.data.getRange(start, end);
	},

	storeOptions: function (o) {
		o = Ext.apply({}, o);
		delete o.callback;
		delete o.scope;
		this.lastOptions = o;
	},

	load: function (options) {
		options = options || {};
		if (this.fireEvent("beforeload", this, options) !== false) {
			this.storeOptions(options);
			var p = Ext.apply(options.params || {}, this.baseParams);
			if (this.sortInfo && this.remoteSort) {
				var pn = this.paramNames;
				p[pn["sort"]] = this.sortInfo.field;
				p[pn["dir"]] = this.sortInfo.direction;
			}
			this.proxy.load(p, this.reader, this.loadRecords, this, options);
			return true;
		} else {
			return false;
		}
	},

	reload: function (options) {
		this.load(Ext.applyIf(options || {}, this.lastOptions));
	},

	loadRecords: function (o, options, success) {
		if (!o || success === false) {
			if (success !== false) {
				this.fireEvent("load", this, [], options);
			}
			if (options.callback) {
				options.callback.call(options.scope || this, [], options, false);
			}
			return;
		}
		var r = o.records, t = o.totalRecords || r.length;
		if (!options || options.add !== true) {
			if (this.pruneModifiedRecords) {
				this.modified = [];
			}
			for (var i = 0, len = r.length; i < len; i++) {
				r[i].join(this);
			}
			if (this.snapshot) {
				this.data = this.snapshot;
				delete this.snapshot;
			}
			this.data.clear();
			this.data.addAll(r);
			this.totalLength = t;
			this.applySort();
			this.fireEvent("datachanged", this);
		} else {
			this.totalLength = Math.max(t, this.data.length + r.length);
			this.add(r);
		}
		this.fireEvent("load", this, r, options);
		if (options.callback) {
			options.callback.call(options.scope || this, r, options, true);
		}
	},

	loadData: function (o, append) {
		var r = this.reader.readRecords(o);
		this.loadRecords(r, { add: append }, true);
	},

	getCount: function () {
		return this.data.length || 0;
	},

	getTotalCount: function () {
		return this.totalLength || 0;
	},

	getSortState: function () {
		return this.sortInfo;
	},

	applySort: function () {
		if (this.sortInfo && !this.remoteSort) {
			var s = this.sortInfo, f = s.field;
			this.sortData(f, s.direction);
		}
	},

	sortData: function (f, direction) {
		var fn, customFunc;
		direction = direction || 'ASC';
		if (this.sortInfo) {
			customFunc = this.sortInfo.func;
		}
		var st = this.fields.get(f).sortType;
		var fn = function (r1, r2) {
			var v1 = st(r1.data[f]), v2 = st(r2.data[f]);
			return customFunc ? customFunc(v1, v2) : v1 > v2 ? 1 : (v1 < v2 ? -1 : 0);
		};
		this.data.sort(direction, fn);
		if (this.snapshot && this.snapshot != this.data) {
			this.snapshot.sort(direction, fn);
		}
	},

	setDefaultSort: function (field, dir) {
		dir = dir ? dir.toUpperCase() : "ASC";
		this.sortInfo = { field: field, direction: dir };
		this.sortToggle[field] = dir;
	},

	setCustomSort: function (field, fn) {
		this.sortInfo = { field: field, func: fn };
	},

	sort: function (fieldName, dir) {
		var f = this.fields.get(fieldName);
		if (!f) {
			return false;
		}
		if (!dir) {
			if (this.sortInfo && this.sortInfo.field == f.name) {
				dir = (this.sortToggle[f.name] || "ASC").toggle("ASC", "DESC");
			} else {
				dir = f.sortDir;
			}
		}
		var st = (this.sortToggle) ? this.sortToggle[f.name] : null;
		var si = (this.sortInfo) ? this.sortInfo : null;

		this.sortToggle[f.name] = dir;
		this.sortInfo = { field: f.name, direction: dir };
		if (!this.remoteSort) {
			this.applySort();
			this.fireEvent("datachanged", this);
		} else {
			if (!this.load(this.lastOptions)) {
				if (st) {
					this.sortToggle[f.name] = st;
				}
				if (si) {
					this.sortInfo = si;
				}
			}
		}
	},

	each: function (fn, scope) {
		this.data.each(fn, scope);
	},

	getModifiedRecords: function () {
		return this.modified;
	},

	createFilterFn: function (property, value, anyMatch, caseSensitive) {
		if (Ext.isEmpty(value, false)) {
			return false;
		}
		value = this.data.createValueMatcher(value, anyMatch, caseSensitive);
		return function (r) {
			return value.test(r.data[property]);
		};
	},

	sum: function (property, start, end) {
		var rs = this.data.items, v = 0;
		start = start || 0;
		end = (end || end === 0) ? end : rs.length - 1;

		for (var i = start; i <= end; i++) {
			v += (rs[i].data[property] || 0);
		}
		return v;
	},

	filter: function (property, value, anyMatch, caseSensitive) {
		var fn = this.createFilterFn(property, value, anyMatch, caseSensitive);
		return fn ? this.filterBy(fn) : this.clearFilter();
	},

	filterBy: function (fn, scope) {
		this.snapshot = this.snapshot || this.data;
		this.data = this.queryBy(fn, scope || this);
		this.fireEvent("datachanged", this);
	},

	query: function (property, value, anyMatch, caseSensitive) {
		var fn = this.createFilterFn(property, value, anyMatch, caseSensitive);
		return fn ? this.queryBy(fn) : this.data.clone();
	},

	queryBy: function (fn, scope) {
		var data = this.snapshot || this.data;
		return data.filterBy(fn, scope || this);
	},

	find: function (property, value, start, anyMatch, caseSensitive) {
		var fn = this.createFilterFn(property, value, anyMatch, caseSensitive);
		return fn ? this.data.findIndexBy(fn, null, start) : -1;
	},

	findBy: function (fn, scope, start) {
		return this.data.findIndexBy(fn, scope, start);
	},

	collect: function (dataIndex, allowNull, bypassFilter) {
		var d = (bypassFilter === true && this.snapshot) ?
                this.snapshot.items : this.data.items;
		var v, sv, r = [], l = {};
		for (var i = 0, len = d.length; i < len; i++) {
			v = d[i].data[dataIndex];
			sv = String(v);
			if ((allowNull || !Ext.isEmpty(v)) && !l[sv]) {
				l[sv] = true;
				r[r.length] = v;
			}
		}
		return r;
	},

	clearFilter: function (suppressEvent) {
		if (this.isFiltered()) {
			this.data = this.snapshot;
			delete this.snapshot;
			if (suppressEvent !== true) {
				this.fireEvent("datachanged", this);
			}
		}
	},

	isFiltered: function () {
		return this.snapshot && this.snapshot != this.data;
	},

	afterEdit: function (record) {
		if (this.modified.indexOf(record) == -1) {
			this.modified.push(record);
		}
		this.fireEvent("update", this, record, Ext.data.Record.EDIT);
	},

	afterReject: function (record) {
		this.modified.remove(record);
		this.fireEvent("update", this, record, Ext.data.Record.REJECT);
	},

	afterCommit: function (record) {
		this.modified.remove(record);
		this.fireEvent("update", this, record, Ext.data.Record.COMMIT);
	},

	commitChanges: function () {
		var m = this.modified.slice(0);
		this.modified = [];
		for (var i = 0, len = m.length; i < len; i++) {
			m[i].commit();
		}
	},

	rejectChanges: function () {
		var m = this.modified.slice(0);
		this.modified = [];
		for (var i = 0, len = m.length; i < len; i++) {
			m[i].reject();
		}
	},

	onMetaChange: function (meta, rtype, o) {
		this.recordType = rtype;
		this.fields = rtype.prototype.fields;
		delete this.snapshot;
		this.sortInfo = meta.sortInfo;
		this.modified = [];
		this.fireEvent('metachange', this, this.reader.meta);
	},

	findInsertIndex: function (record) {
		this.suspendEvents();
		var data = this.data.clone();
		this.data.add(record);
		this.applySort();
		var index = this.data.indexOf(record);
		this.data = data;
		this.resumeEvents();
		return index;
	}
});

Ext.data.SimpleStore = function (config) {
	Ext.data.SimpleStore.superclass.constructor.call(this, Ext.apply(config, {
		reader: new Ext.data.ArrayReader({
			id: config.id
		},
            Ext.data.Record.create(config.fields)
        )
	}));
};
Ext.extend(Ext.data.SimpleStore, Ext.data.Store, {
	loadData: function (data, append) {
		if (this.expandData === true) {
			var r = [];
			for (var i = 0, len = data.length; i < len; i++) {
				r[r.length] = [data[i]];
			}
			data = r;
		}
		Ext.data.SimpleStore.superclass.loadData.call(this, data, append);
	},

	findByValue: function (value) {
		for (var i = 0, len = this.data.items.length; i < len; i++) {
			var item = this.data.items[i];
			if (item.data.value == value) {
				return item;
			}
		}
		return null;
	},

	findInsertIndex: function (record) {
		var len = this.data.items.length || 0;
		for (var i = 0; i < len; i++) {
			var item = this.data.items[i];
			if (item.data.text > record.data.text) {
				return i;
			}
		}
		return len;
	}
});

Ext.data.JsonStore = function (c) {
	Ext.data.JsonStore.superclass.constructor.call(this, Ext.apply(c, {
		proxy: c.proxy || (!c.data ? new Ext.data.HttpProxy({ url: c.url }) : undefined),
		reader: new Ext.data.JsonReader(c, c.fields)
	}));
};
Ext.extend(Ext.data.JsonStore, Ext.data.Store);

Ext.data.Field = function (config) {
	if (typeof config == "string") {
		config = { name: config };
	}
	Ext.apply(this, config);

	if (!this.type) {
		this.type = "auto";
	}

	var st = Ext.data.SortTypes;

	if (typeof this.sortType == "string") {
		this.sortType = st[this.sortType];
	}
	if (!this.sortType) {
		switch (this.type) {
			case "string":
				this.sortType = st.asUCString;
				break;
			case "date":
				this.sortType = st.asDate;
				break;
			default:
				this.sortType = st.none;
		}
	}

	var stripRe = /[\$,%]/g;

	if (!this.convert) {
		var cv, dateFormat = this.dateFormat;
		switch (this.type) {
			case "":
			case "auto":
			case undefined:
				cv = function (v) { return v; };
				break;
			case "string":
				cv = function (v) { return (v === undefined || v === null) ? '' : String(v); };
				break;
			case "int":
				cv = function (v) {
					return v !== undefined && v !== null && v !== '' ?
                           parseInt(String(v).replace(stripRe, ""), 10) : '';
				};
				break;
			case "float":
				cv = function (v) {
					return v !== undefined && v !== null && v !== '' ?
                           parseFloat(String(v).replace(stripRe, ""), 10) : '';
				};
				break;
			case "bool":
			case "boolean":
				cv = function (v) { return v === true || v === "true" || v == 1; };
				break;
			case "date":
				cv = function (v) {
					if (!v) {
						return '';
					}
					if (Ext.isDate(v)) {
						return v;
					}
					if (dateFormat) {
						if (dateFormat == "timestamp") {
							return new Date(v * 1000);
						}
						if (dateFormat == "time") {
							return new Date(parseInt(v, 10));
						}
						return Date.parseDate(v, dateFormat);
					}
					var parsed = Date.parse(v);
					return parsed ? new Date(parsed) : null;
				};
				break;
		}
		this.convert = cv;
	}
};

Ext.data.Field.prototype = {
	dateFormat: null,
	defaultValue: "",
	mapping: null,
	sortType: null,
	sortDir: "ASC"
};

Ext.data.DataReader = function (meta, recordType) {

	this.meta = meta;
	this.recordType = Ext.isArray(recordType) ?
        Ext.data.Record.create(recordType) : recordType;
};

Ext.data.DataReader.prototype = {

};

Ext.data.DataProxy = function () {
	this.addEvents(
		'beforeload',
		'load'
    );
	Ext.data.DataProxy.superclass.constructor.call(this);
};

Ext.extend(Ext.data.DataProxy, Ext.util.Observable);

Ext.data.MemoryProxy = function (data) {
	Ext.data.MemoryProxy.superclass.constructor.call(this);
	this.data = data;
};

Ext.extend(Ext.data.MemoryProxy, Ext.data.DataProxy, {

	load: function (params, reader, callback, scope, arg) {
		params = params || {};
		var result;
		try {
			result = reader.readRecords(this.data);
		} catch (e) {
			this.fireEvent("loadexception", this, arg, null, e);
			callback.call(scope, null, arg, false);
			return;
		}
		callback.call(scope, result, arg, true);
	},

	update: function (params, records) {
	}
});

Ext.data.HttpProxy = function (conn) {
	Ext.data.HttpProxy.superclass.constructor.call(this);

	this.conn = conn;
	this.useAjax = !conn || !conn.events;
};

Ext.extend(Ext.data.HttpProxy, Ext.data.DataProxy, {

	getConnection: function () {
		return this.useAjax ? Ext.Ajax : this.conn;
	},

	load: function (params, reader, callback, scope, arg) {
		if (this.fireEvent("beforeload", this, params) !== false) {
			var o = {
				params: params || {},
				request: {
					callback: callback,
					scope: scope,
					arg: arg
				},
				reader: reader,
				callback: this.loadResponse,
				scope: this
			};
			if (this.useAjax) {
				Ext.applyIf(o, this.conn);
				if (this.activeRequest) {
					Ext.Ajax.abort(this.activeRequest);
				}
				this.activeRequest = Ext.Ajax.request(o);
			} else {
				this.conn.request(o);
			}
		} else {
			callback.call(scope || this, null, arg, false);
		}
	},

	loadResponse: function (o, success, response) {
		delete this.activeRequest;
		if (!success) {
			this.fireEvent("loadexception", this, o, response);
			o.request.callback.call(o.request.scope, null, o.request.arg, false);
			return;
		}
		var result;
		try {
			result = o.reader.read(response);
		} catch (e) {
			this.fireEvent("loadexception", this, o, response, e);
			o.request.callback.call(o.request.scope, null, o.request.arg, false);
			return;
		}
		this.fireEvent("load", this, o, o.request.arg);
		o.request.callback.call(o.request.scope, result, o.request.arg, true);
	},

	update: function (dataSet) {
	},

	updateResponse: function (dataSet) {
	}
});

Ext.data.ScriptTagProxy = function (config) {
	Ext.data.ScriptTagProxy.superclass.constructor.call(this);
	Ext.apply(this, config);
	this.head = document.getElementsByTagName("head")[0];
};

Ext.data.ScriptTagProxy.TRANS_ID = 1000;

Ext.extend(Ext.data.ScriptTagProxy, Ext.data.DataProxy, {
	timeout: 30000,
	callbackParam: "callback",
	nocache: true,

	load: function (params, reader, callback, scope, arg) {
		if (this.fireEvent("beforeload", this, params) !== false) {
			var p = Ext.urlEncode(Ext.apply(params, this.extraParams));

			var url = this.url;
			url += (url.indexOf("?") != -1 ? "&" : "?") + p;
			if (this.nocache) {
				url += "&_dc=" + (new Date().getTime());
			}
			var transId = ++Ext.data.ScriptTagProxy.TRANS_ID;
			var trans = {
				id: transId,
				cb: "stcCallback" + transId,
				scriptId: "stcScript" + transId,
				params: params,
				arg: arg,
				url: url,
				callback: callback,
				scope: scope,
				reader: reader
			};
			var conn = this;

			window[trans.cb] = function (o) {
				conn.handleResponse(o, trans);
			};

			url += String.format("&{0}={1}", this.callbackParam, trans.cb);

			if (this.autoAbort !== false) {
				this.abort();
			}

			trans.timeoutId = this.handleFailure.defer(this.timeout, this, [trans]);

			var script = document.createElement("script");
			script.setAttribute("src", url);
			script.setAttribute("type", "text/javascript");
			script.setAttribute("id", trans.scriptId);
			this.head.appendChild(script);

			this.trans = trans;
		} else {
			callback.call(scope || this, null, arg, false);
		}
	},

	isLoading: function () {
		return this.trans ? true : false;
	},

	abort: function () {
		if (this.isLoading()) {
			this.destroyTrans(this.trans);
		}
	},

	destroyTrans: function (trans, isLoaded) {
		this.head.removeChild(document.getElementById(trans.scriptId));
		clearTimeout(trans.timeoutId);
		if (isLoaded) {
			window[trans.cb] = undefined;
			try {
				delete window[trans.cb];
			} catch (e) { }
		} else {

			window[trans.cb] = function () {
				window[trans.cb] = undefined;
				try {
					delete window[trans.cb];
				} catch (e) { }
			};
		}
	},

	handleResponse: function (o, trans) {
		this.trans = false;
		this.destroyTrans(trans, true);
		var result;
		try {
			result = trans.reader.readRecords(o);
		} catch (e) {
			this.fireEvent("loadexception", this, o, trans.arg, e);
			trans.callback.call(trans.scope || window, null, trans.arg, false);
			return;
		}
		this.fireEvent("load", this, o, trans.arg);
		trans.callback.call(trans.scope || window, result, trans.arg, true);
	},

	handleFailure: function (trans) {
		this.trans = false;
		this.destroyTrans(trans, false);
		this.fireEvent("loadexception", this, null, trans.arg);
		trans.callback.call(trans.scope || window, null, trans.arg, false);
	}
});

Ext.data.JsonReader = function (meta, recordType) {
	meta = meta || {};
	Ext.data.JsonReader.superclass.constructor.call(this, meta, recordType || meta.fields);
};

Ext.extend(Ext.data.JsonReader, Ext.data.DataReader, {

	read: function (response) {
		var json = response.responseText;
		var o = eval("(" + json + ")");
		if (!o) {
			throw { message: "JsonReader.read: JSON объект не найден" };
		}
		return this.readRecords(o);
	},

	onMetaChange: function (meta, recordType, o) {
	},

	simpleAccess: function (obj, subsc) {
		return obj[subsc];
	},

	getJsonAccessor: function () {
		var re = /[\[\.]/;
		return function (expr) {
			try {
				return (re.test(expr))
                    ? new Function("obj", "return obj." + expr)
                    : function (obj) {
                    	return obj[expr];
                    };
			} catch (e) { }
			return Ext.emptyFn;
		};
	} (),

	readRecords: function (o) {
		this.jsonData = o;
		if (o.metaData) {
			delete this.ef;
			this.meta = o.metaData;
			this.recordType = Ext.data.Record.create(o.metaData.fields);
			this.onMetaChange(this.meta, this.recordType, o);
		}
		var s = this.meta, Record = this.recordType,
            f = Record.prototype.fields, fi = f.items, fl = f.length;

		if (!this.ef) {
			if (s.totalProperty) {
				this.getTotal = this.getJsonAccessor(s.totalProperty);
			}
			if (s.successProperty) {
				this.getSuccess = this.getJsonAccessor(s.successProperty);
			}
			this.getRoot = s.root ? this.getJsonAccessor(s.root) : function (p) { return p; };
			if (s.id) {
				var g = this.getJsonAccessor(s.id);
				this.getId = function (rec) {
					var r = g(rec);
					return (r === undefined || r === "") ? null : r;
				};
			} else {
				this.getId = function () { return null; };
			}
			this.ef = [];
			for (var i = 0; i < fl; i++) {
				f = fi[i];
				var map = (f.mapping !== undefined && f.mapping !== null) ? f.mapping : f.name;
				this.ef[i] = this.getJsonAccessor(map);
			}
		}

		var root = this.getRoot(o), c = root.length, totalRecords = c, success = true;
		if (s.totalProperty) {
			var v = parseInt(this.getTotal(o), 10);
			if (!isNaN(v)) {
				totalRecords = v;
			}
		}
		if (s.successProperty) {
			var v = this.getSuccess(o);
			if (v === false || v === 'false') {
				success = false;
			}
		}
		var records = [];
		for (var i = 0; i < c; i++) {
			var n = root[i];
			var values = {};
			var id = this.getId(n);
			for (var j = 0; j < fl; j++) {
				f = fi[j];
				var v = this.ef[j](n);
				values[f.name] = f.convert((v !== undefined) ? v : f.defaultValue, n);
			}
			var record = new Record(values, id);
			record.json = n;
			records[i] = record;
		}
		return {
			success: success,
			records: records,
			totalRecords: totalRecords
		};
	}
});

Ext.data.XmlReader = function (meta, recordType) {
	meta = meta || {};
	Ext.data.XmlReader.superclass.constructor.call(this, meta, recordType || meta.fields);
};

Ext.extend(Ext.data.XmlReader, Ext.data.DataReader, {

	read: function (response) {
		var doc = response.responseXML;
		if (!doc) {
			throw { message: "XmlReader.read: XML документ не доступен" };
		}
		return this.readRecords(doc);
	},

	readRecords: function (doc) {
		this.xmlData = doc;
		var root = doc.documentElement || doc;
		var q = Ext.DomQuery;
		var recordType = this.recordType, fields = recordType.prototype.fields;
		var sid = this.meta.id;
		var totalRecords = 0, success = true;
		if (this.meta.totalRecords) {
			totalRecords = q.selectNumber(this.meta.totalRecords, root, 0);
		}

		if (this.meta.success) {
			var sv = q.selectValue(this.meta.success, root, true);
			success = sv !== false && sv !== 'false';
		}
		var records = [];
		var ns = q.select(this.meta.record, root);
		for (var i = 0, len = ns.length; i < len; i++) {
			var n = ns[i];
			var values = {};
			var id = sid ? q.selectValue(sid, n) : undefined;
			for (var j = 0, jlen = fields.length; j < jlen; j++) {
				var f = fields.items[j];
				var v = q.selectValue(f.mapping || f.name, n, f.defaultValue);
				v = f.convert(v, n);
				values[f.name] = v;
			}
			var record = new recordType(values, id);
			record.node = n;
			records[records.length] = record;
		}

		return {
			success: success,
			records: records,
			totalRecords: totalRecords || records.length
		};
	}
});

Ext.data.ArrayReader = Ext.extend(Ext.data.JsonReader, {
	isArrayReader: true,

	readRecords: function (o) {
		var sid = this.meta ? this.meta.id : null;
		var recordType = this.recordType, fields = recordType.prototype.fields;
		var records = [];
		var root = o;
		for (var i = 0; i < root.length; i++) {
			var n = root[i];
			var values = {};
			var id = ((sid || sid === 0) && n[sid] !== undefined && n[sid] !== "" ? n[sid] : null);
			for (var j = 0, jlen = fields.length; j < jlen; j++) {
				var f = fields.items[j];
				var k = f.mapping !== undefined && f.mapping !== null ? f.mapping : j;
				var v = n[k] !== undefined ? n[k] : f.defaultValue;
				v = f.convert(v, n);
				values[f.name] = v;
			}
			var record = new recordType(values, id);
			record.json = n;
			records[records.length] = record;
		}
		return {
			records: records,
			totalRecords: records.length
		};
	}
});

Ext.Link = function () {

	var linkTpl = new Ext.Template('<a linkId="{linkId}" class="x-link {cls} {imageCls}" {style} href="{url}">{caption}</a>');
	linkTpl.compile();

	return {

		applyLinks: function (source, links) {
			if (Ext.isEmpty(source) || Ext.isEmpty(links)) {
				return source || '';
			}
			if (!Ext.isArray(links)) {
				links = [links];
			}
			for (var i = 0; i < links.length; i++) {
				var re = new RegExp('\\{' + links[i].linkId + '\\}', 'ig');
				var l = links[i], imgSrc = Ext.ImageUrlHelper.getImageUrl({ resourceManager: l.imageList, resourceId: l.imageId, resourceName: l.imageName }),
					linkCfg = { linkId: l.linkId, url: (l.url || "#"), caption: (l.caption || ""), cls: (l.cls || "") };
				var style = 'style="padding-left:16px;background:transparent ' + imgSrc + ' no-repeat 0 center;"';
				linkCfg = Ext.isEmpty(imgSrc) ? Ext.apply(linkCfg, { imageCls: (l.imageCls || "") }) : Ext.apply(linkCfg, { style: style });
				var link = linkTpl.apply(linkCfg);
				source = source.replace(re, link);
			}
			return source;
		},

		getLinks: function (o) {
			if (Ext.isEmpty(o)) {
				return [];
			}
			return Ext.fly(o).select("a.x-link");
		},

		onClick: function (e) {
			var t = e.getTarget();
			if (Ext.fly(t).hasClass("x-link")) {
				var href;
				if (!Ext.isEmpty(href = t.getAttribute('href')) && (href.charAt(href.length - 1) == '#')) {
					e.stopEvent();
					this.fireEvent("linkclick", t, t.getAttribute("linkId"));
				}
			}
		},

		onFocus: function (event, el) {
			var target = event.getTarget();
			if (Ext.fly(target).hasClass("x-link")) {
				var href;
				if (!Ext.isEmpty(href = target.getAttribute('href')) && (href.charAt(href.length - 1) == '#')) {
					event.preventDefault();
					this.fireEvent("linkFocused", target, target.getAttribute("linkId"));
				}
			}
		}
	};
} ();

Ext.ComponentMgr = function () {
	var all = new Ext.util.MixedCollection();
	var types = {};

	return {
		register: function (c) {
			all.add(c);
		},

		unregister: function (c) {
			all.remove(c);
			if (window[c.id]) {
				window[c.id] = null;
			}
		},

		get: function (id) {
			return all.get(id);
		},

		onAvailable: function (id, fn, scope) {
			all.on("add", function (index, o) {
				if (o.id == id) {
					fn.call(scope || o, o);
					all.un("add", fn, scope);
				}
			});
		},

		all: all,

		registerType: function (xtype, cls) {
			types[xtype] = cls;
			cls.xtype = xtype;
		},

		create: function (config, defaultType) {
			return new types[config.xtype || defaultType](config);
		}
	};
} ();

Ext.reg = Ext.ComponentMgr.registerType; // this will be called a lot internally, shorthand to keep the bytes down

Ext.Component = function (config) {
	config = config || {};
	if (config.initialConfig) {
		if (config.isAction) {
			this.baseAction = config;
		}
		config = config.initialConfig;
	} else if (config.tagName || config.dom || typeof config == "string") {
		config = { applyTo: config, id: config.id || config };
	}

	this.initialConfig = config;

	Ext.apply(this, config);
	this.addEvents(
		'disable',
		'enable',
		'beforeshow',
		'show',
		'beforehide',
		'hide',
		'beforerender',
		'render',
		'beforedestroy',
		'destroy',
		'beforestaterestore',
		'staterestore',
		'beforestatesave',
		'statesave',
		'contextmenu',
		'rendercomplete',
		'nameChanged'
	);
	this.getId();
	Ext.ComponentMgr.register(this);
	Ext.Component.superclass.constructor.call(this);

	if (this.baseAction) {
		this.baseAction.addComponent(this);
	}

	var initResult = this.initComponent();
	if (initResult !== false) {
		this.afterInit(config);
	}
};

Ext.Component.AUTO_ID = 1000;

(function () {
	Ext.ImageUrlHelper = function () {
	};

	Ext.ImageUrlHelper.DesignSchemaManagerName = null;

	Ext.ImageUrlHelper.getImageUrl = function (o) {
		if (Ext.isEmpty(o)) {
			return '';
		}
		var imageNotFoundUrl = String.format('./terrasoft.axd?s=res&rm={0}&r={1}',
			'Terrasoft.UI.WebControls', 'imagenotfound-ico.png');
		var notWrap = o.notWrap;
		imageNotFoundUrl = notWrap ? imageNotFoundUrl : String.format('url({0})', imageNotFoundUrl);

		var url = '';
		var source = o.source;
		var resourceManager = o.resourceManager;
		var resourceName = o.resourceName;
		var schemaName = o.schemaName;
		var schemaId = o.schemaId;
		var resourceId = o.resourceId;
		var resourceColumnUId = o.entitySchemaColumnUId;
		var useDesignMode = o.useDesignMode;
		var column = o.column;
		var id = o.id;

		if (!Ext.isEmpty(source)) {
			switch (source) {
				case 'res':
					if (!Ext.isEmpty(resourceManager)) {
						if (!Ext.isEmpty(resourceName)) {
							url = String.format('./terrasoft.axd?s=res&rm={0}&r={1}', resourceManager, resourceName);
						} else {
							return imageNotFoundUrl;
						}
					}
					break;
				case 'shm':
					if (!Ext.isEmpty(schemaId)) {
						if (!Ext.isEmpty(resourceId)) {
							url = String.format('./terrasoft.axd?s=shm&sid={0}&r={1}', schemaId, resourceId);
						} else if (!Ext.isEmpty(resourceName)) {
							url = String.format('./terrasoft.axd?s=shm&sid={0}&r={1}', schemaId, resourceName);
						} else {
							return imageNotFoundUrl;
						}
					} else if (!Ext.isEmpty(schemaName)) {
						if (resourceName) {
							url = String.format('./terrasoft.axd?s=shm&sn={0}&r={1}', schemaName, resourceName);
						} else {
							return imageNotFoundUrl;
						}
					} else if (!Ext.isEmpty(resourceManager)) {
						if (resourceName) {
							url = String.format('./terrasoft.axd?s=shm&rm={0}&r={1}', resourceManager, resourceName);
						} else {
							return imageNotFoundUrl;
						}
					}
					break;
				case 'db':
					if (!Ext.isEmpty(column) && !Ext.isEmpty(id)) {
						url = (Ext.isEmpty(column.refSchemaPrimaryImageColumnName)) ? '' :
							String.format('./terrasoft.axd?s=db&sn={0}&id={1}&sc={3}',
								column.refSchemaName, id, resourceColumnUId);
						return notWrap ? url : String.format("url('{0}')", url);
					} else if (!Ext.isEmpty(schemaId) && !Ext.isEmpty(id)) {
						url = String.format('./terrasoft.axd?s=db&sn={0}&id={1}&t={2}&sc={3}',
							schemaId, id, o.imageHash, resourceColumnUId);
						return notWrap ? url : String.format("url('{0}')", url);
					}
					break;
				default:
					return '';
			}
		} else if (!Ext.isEmpty(resourceManager)) {
			source = 'res';
			if (!Ext.isEmpty(resourceName)) {
				url = String.format('./terrasoft.axd?s=res&rm={0}&r={1}', resourceManager, resourceName);
			} else {
				return imageNotFoundUrl;
			}
		} else if (!Ext.isEmpty(schemaId)) {
			source = 'shm';
			if (!Ext.isEmpty(resourceId)) {
				url = String.format('./terrasoft.axd?s=shm&sid={0}&r={1}', schemaId, resourceId);
			} else if (!Ext.isEmpty(resourceName)) {
				url = String.format('./terrasoft.axd?s=shm&sid={0}&r={1}', schemaId, resourceName);
			} else {
				return imageNotFoundUrl;
			}
		} else if (!Ext.isEmpty(schemaName)) {
			source = 'shm';
			if (resourceName) {
				url = String.format('./terrasoft.axd?s=shm&sn={0}&r={1}', schemaName, resourceName);
			} else {
				return imageNotFoundUrl;
			}
		} else if (!Ext.isEmpty(column) && !Ext.isEmpty(id)) {
			source = 'db';
			return (Ext.isEmpty(column.refSchemaPrimaryImageColumnName)) ? '' :
				String.format('./terrasoft.axd?s=db&sn={0}&id={1}&sc={3}',
					column.refSchemaName, id, resourceColumnUId);
		}
		if (Ext.isEmpty(url)) {
			return '';
		}
		var concatDesignSchemaManagerName = (useDesignMode !== false);
		if (source == 'shm') {
			//url = String.format('{0}&t={1}', url, Math.random());
			url = String.format('{0}&t={1}', url, o.imageHash);
		}
		if (source == 'shm' && !Ext.isEmpty(Ext.ImageUrlHelper.DesignSchemaManagerName)) {
			if (concatDesignSchemaManagerName) {
				url = String.format('{0}&sm={1}', url, Ext.ImageUrlHelper.DesignSchemaManagerName);
			}
		}
		return notWrap ? url : String.format("url('{0}')", url);
	};

	Ext.StringList = function (name) {
		var stringList = Ext.StringList[name];

		return (stringList) ? {
			name: name,

			getValue: function (id) {
				var item = stringList.find(function (item, key) {
					return (id == key || id == item.name) ? true : false;
				})
				if (!item) {
					throw 'In StringList "' + this.name + '" item "' + id + '" is undefined';
				}
				return item.value;
			},
			getValuesByPrefix: function (prefix) {
				prefix += '.';
				return stringList.filterBy(function (item, key) {
					if (item.name.indexOf(prefix) == 0) {
						return true;
					}
					return false;
				});
			}
		} : null;
	};
})();

Ext.extend(Ext.Component, Ext.util.Observable, {
	designMode: false,
	disabledClass: "x-item-disabled",
	allowDomMove: true,
	autoShow: false,
	hideMode: 'display',
	hideParent: false,
	hidden: false,
	enabled: true,
	rendered: false,
	ctype: "Ext.Component",
	actionMode: "el",

	getActionEl: function () {
		return this[this.actionMode];
	},

	initPlugin: function (p) {
		p.init(this);
		return p;
	},

	initComponent: function () {
		if (this.designMode) {
			Terrasoft.lazyInit([this.id]);
			this.addClass('x-design');
			if (this.designConfig) {
				this.applyDesignConfig(this.designConfig);
			}
		}
	},

	applyDesignConfig: Ext.emptyFn,

	setHidden: function (hidden) {
		this.hidden = hidden;
		this.visible = !hidden;
		if (!this.rendered) {
			return;
		}
		if (!this.hidden) {
			this.show();
		} else {
			this.hide();
		}
	},

	handleNameChanging: function (oldName, name, force) {
		var el = this.el;
		var dom = el.dom;
		window[oldName] = undefined;
		Ext.ComponentMgr.unregister(this);
		this.id = name;
		el.id = name;
		Ext.Element.uncache(oldName);
		if (dom) {
			dom.id = name;
			if (dom.name) {
				dom.name = name;
			}
		}
		Ext.Element.cache[name] = el;
		if (force !== true) {
			this.fireEvent("nameChanged", this, oldName, name);
		}
	},

	render: function (container, position) {
		if (!this.rendered && this.fireEvent("beforerender", this) !== false) {
			if (!container && this.el) {
				this.el = Ext.get(this.el);
				container = this.el.dom.parentNode;
				this.allowDomMove = false;
			}
			this.container = Ext.get(container);
			if (!this.container) {
				this.autoCreateContainer(container);
			}
			if (this.ctCls) {
				this.container.addClass(this.ctCls);
			}
			this.rendered = true;
			if (position !== undefined) {
				if (typeof position == 'number') {
					position = this.container.dom.childNodes[position];
				} else {
					position = Ext.getDom(position);
				}
			}
			this.onRender(this.container, position || null);
			if (this.autoShow) {
				this.el.removeClass(['x-hidden', 'x-hide-' + this.hideMode]);
			}
			if (this.cls && this.el) {
				this.el.addClass(this.cls);
				delete this.cls;
			}
			if (this.style) {
				this.el.applyStyles(this.style);
				delete this.style;
			}
			this.fireEvent("render", this);
			this.afterRender(this.container);
			if (this.hidden && !this.ownerCt) {
				this.hide();
			}
			if (!this.enabled) {
				this.disable();
			}
			if (this.stateful !== false) {
				this.initStateEvents();
			}
			var el = this.getEl();
			if (el) {
				el.on('contextmenu', function () {
					this.fireEvent("contextmenu", this);
				}, this);
			}
			this.fireEvent('rendercomplete', this);
		}
		return this;
	},

	getImageSrc: function (value) {
		var imageCfg, imageSrc;
		if (value) {
			imageCfg = this.getImageConfigWrapper(value);
			if (imageCfg.source == "Url") {
				imageSrc = String.format((imageCfg.notWrap ? "{0}" : "url('{0}')"), imageCfg.url);
			} else {
				imageSrc = Ext.ImageUrlHelper.getImageUrl(imageCfg);
			}
			return Ext.isEmpty(imageSrc) ? this.imageUrl || Ext.BLANK_IMAGE_URL : imageSrc;
		}
		imageCfg = this.getImageConfigWrapper(this.imageConfig);
		if (imageCfg.source == null) {
			return '';
		}
		if (imageCfg.source == "Url") {
			imageSrc = String.format("url('{0}')", imageCfg.url);
		} else {
			if (Ext.isEmpty(imageSrc = Ext.ImageUrlHelper.getImageUrl(imageCfg))) {
				imageSrc = (this.imageUrl || Ext.BLANK_IMAGE_URL);
			}
		}
		return imageSrc;
	},

	getImageConfigWrapper: function (imageConfig) {
		var imageCfgWrapper;
		if (imageConfig == undefined || imageConfig.source == "None") {
			imageCfgWrapper = this.imageConfig || {
				resourceManager: this.imageList,
				resourceId: this.imageId,
				resourceName: this.imageName,
				schemaId: this.schemaId,
				useDesignMode: this.useDesignMode,
				notWrap: false,
				column: this.dataSource ? this.getColumn() : null,
				id: this.dataSource && this.getValue ? this.getValue() : null
			};
			imageCfgWrapper.source = '';
			this.imageConfig = { source: '' };
		} else {
			imageCfgWrapper = {
				resourceName: this.imageName,
				schemaId: imageConfig.schemaUId,
				notWrap: imageConfig.notWrap == undefined ? false : imageConfig.notWrap
			};
			switch (imageConfig.source) {
				case 'None':
					imageCfgWrapper.source = null;
				case 'Url':
					imageCfgWrapper.source = imageConfig.source;
					var imageUrl = imageConfig.url ? imageConfig.url : '';
					imageUrl = imageUrl.indexOf('http') != -1 ? imageUrl : './' + imageUrl;
					imageCfgWrapper.url = imageUrl;
					break;
				case 'Image':
					imageCfgWrapper.source = 'shm';
					imageCfgWrapper.resourceName = imageConfig.resourceName;
					break;
				case 'ImageListSchema':
					imageCfgWrapper.source = 'shm';
					imageCfgWrapper.resourceId = imageConfig.itemUId;
					imageCfgWrapper.useDesignMode =
						(Ext.ImageUrlHelper.DesignSchemaManagerName == 'ImageListSchemaManager');
					break;
				case 'ImageList':
					imageCfgWrapper.source = 'shm';
					imageCfgWrapper.resourceId = imageConfig.imageUId;
					imageCfgWrapper.useDesignMode = true;
					break;
				case 'ResourceManager':
					imageCfgWrapper.source = 'res';
					imageCfgWrapper.schemaId = null;
					imageCfgWrapper.resourceManager = imageConfig.resourceManagerName;
					imageCfgWrapper.resourceName = imageConfig.resourceItemName;
					break;
				case 'EntityColumn':
					imageCfgWrapper.source = 'db';
					imageCfgWrapper.schemaId = imageConfig.schemaUId;
					imageCfgWrapper.id = imageConfig.entityPrimaryColumnValue;
					imageCfgWrapper.entitySchemaColumnUId = imageConfig.entitySchemaColumnUId;
					break;
				default:
					imageCfgWrapper.source = null;
			}
			imageCfgWrapper.imageHash = imageConfig.imageHash;
		}
		return imageCfgWrapper;
	},

	autoCreateContainer: function (container) {
		var containerDiv = document.createElement("div");
		containerDiv.id = container;
		if (this.parentWindowId) {
			Ext.getDom(this.parentWindowId).appendChild(containerDiv);
		} else {
			Ext.getBody().appendChild(containerDiv);
		}
		this.container = Ext.get(container);
	},

	autoCreateContentElement: function (contentElement) {
		var contentElDiv = document.createElement("div");
		contentElDiv.id = contentElement;
		this.container.dom.appendChild(contentElDiv);
	},

	initState: function (config) {
		if (Ext.state.Manager) {
			var state = Ext.state.Manager.get(this.stateId || this.id);
			if (state) {
				if (this.fireEvent('beforestaterestore', this, state) !== false) {
					this.applyState(state);
					this.fireEvent('staterestore', this, state);
				}
			}
		}
	},

	initStateEvents: function () {
		if (this.stateEvents) {
			for (var i = 0, e; e = this.stateEvents[i]; i++) {
				this.on(e, this.saveState, this, { delay: 100 });
			}
		}
	},

	afterInit: function (config) {
		if (this.plugins) {
			if (Ext.isArray(this.plugins)) {
				for (var i = 0, len = this.plugins.length; i < len; i++) {
					this.plugins[i] = this.initPlugin(this.plugins[i]);
				}
			} else {
				this.plugins = this.initPlugin(this.plugins);
			}
		}
		if (this.stateful !== false) {
			this.initState(config);
		}
		if (this.applyTo) {
			this.applyToMarkup(this.applyTo);
			delete this.applyTo;
		} else if (this.renderTo) {
			this.render(this.renderTo);
			delete this.renderTo;
		}
	},

	applyState: function (state, config) {
		if (state) {
			Ext.apply(this, state);
		}
	},

	getState: function () {
		return null;
	},

	saveState: function () {
		if (Ext.state.Manager) {
			var state = this.getState();
			if (this.fireEvent('beforestatesave', this, state) !== false) {
				Ext.state.Manager.set(this.stateId || this.id, state);
				this.fireEvent('statesave', this, state);
			}
		}
	},

	applyToMarkup: function (el) {
		this.allowDomMove = false;
		this.el = Ext.get(el);
		this.render(this.el.dom.parentNode);
	},

	addClass: function (cls) {
		if (this.el) {
			this.el.addClass(cls);
		} else {
			this.cls = this.cls ? this.cls + ' ' + cls : cls;
		}
	},

	removeClass: function (cls) {
		if (this.el) {
			this.el.removeClass(cls);
		} else if (this.cls) {
			this.cls = this.cls.split(' ').remove(cls).join(' ');
		}
	},

	onRender: function (ct, position) {
		if (this.autoEl) {
			if (typeof this.autoEl == 'string') {
				this.el = document.createElement(this.autoEl);
			} else {
				var div = document.createElement('div');
				Ext.DomHelper.overwrite(div, this.autoEl);
				this.el = div.firstChild;
			}
			if (!this.el.id) {
				this.el.id = this.getId();
			}
		}
		if (this.el) {
			this.el = Ext.get(this.el);
			if (this.allowDomMove !== false) {
				ct.dom.insertBefore(this.el.dom, position);
			}
			if (this.overCls) {
				this.el.addClassOnOver(this.overCls);
			}
		}
	},

	getAutoCreate: function () {
		var cfg = typeof this.autoCreate == "object" ?
                      this.autoCreate : Ext.apply({}, this.defaultAutoCreate);
		if (this.id && !cfg.id) {
			cfg.id = this.id;
		}
		return cfg;
	},

	afterRender: function () {
		this.initContextMenu();
	},

	destroy: function () {
		if (this.fireEvent("beforedestroy", this) !== false) {
			this.beforeDestroy();
			if (this.rendered) {
				this.el.removeAllListeners();
				this.el.remove();
				if (this.actionMode == "container") {
					this.container.remove();
				}
			}
			var labelEl = this.getLabelEl();
			if (labelEl) {
				labelEl.removeAllListeners();
				labelEl.remove();
			}
			this.onDestroy();
			Ext.ComponentMgr.unregister(this);
			this.fireEvent("destroy", this);
			this.purgeListeners();
		}
	},

	beforeDestroy: Ext.emptyFn,

	onDestroy: Ext.emptyFn,

	getEl: function () {
		return this.el;
	},

	getLabelEl: function () {
		return this.labelEl;
	},

	getId: function () {
		return this.id || (this.id = "ext-comp-" + (++Ext.Component.AUTO_ID));
	},

	getItemId: function () {
		return this.itemId || this.getId();
	},

	focus: function (selectText, delay) {
		if (delay) {
			this.focus.defer(typeof delay == 'number' ? delay : 10, this, [selectText, false]);
			return;
		}
		if (this.rendered) {
			this.getFocusEl().focus();
			if (selectText === true) {
				this.getFocusEl().dom.select();
			}
		}
		return this;
	},

	getFocusEl: function () {
		return this.el;
	},

	blur: function () {
		if (this.rendered) {
			this.el.blur();
		}
		return this;
	},

	disable: function () {
		if (this.rendered) {
			this.onDisable();
		}
		this.enabled = false;
		this.fireEvent("disable", this);
		return this;
	},

	onDisable: function () {
		this.getActionEl().addClass(this.disabledClass);
		var labelEl = this.getLabelEl();
		if (labelEl) {
			labelEl.addClass('x-form-item-label-disabled');
		}
		this.el.dom.readOnly = true;
	},

	enable: function() {
		if (this.rendered) {
			this.onEnable();
		}
		this.enabled = true;
		this.fireEvent("enable", this);
		return this;
	},

	onEnable: function () {
		this.getActionEl().removeClass(this.disabledClass);
		var labelEl = this.getLabelEl();
		if (labelEl) {
			labelEl.removeClass('x-form-item-label-disabled');
		}
		this.el.dom.readOnly = false;
	},

	setEnabled: function(enabled) {
		if (enabled) {
			this.enable();
		} else {
			this.disable();
		}
	},

	setDisabled: function(disabled) {
		if (disabled) {
			this.disable();
		} else {
			this.enable();
		}
	},

	show: function () {
		if (this.fireEvent("beforeshow", this) !== false) {
			this.hidden = false;
			if (this.autoRender) {
				this.render(typeof this.autoRender == 'boolean' ? Ext.getBody() : this.autoRender);
			}
			if (this.rendered) {
				this.onShow();
			}
			this.fireEvent("show", this);
		}
		return this;
	},

	onShow: function () {
		if (this.hideParent) {
			this.container.removeClass('x-hide-' + this.hideMode);
		} else {
			this.getActionEl().removeClass('x-hide-' + this.hideMode);
			var labelEl = this.getLabelEl();
			if (labelEl) {
				labelEl.show();
			}
		}

	},

	hide: function () {
		if (this.fireEvent("beforehide", this) !== false) {
			this.hidden = true;
			if (this.rendered) {
				this.onHide();
			}
			this.fireEvent("hide", this);
		}
		return this;
	},

	onHide: function () {
		if (this.hideParent) {
			this.container.addClass('x-hide-' + this.hideMode);
		} else {
			this.getActionEl().addClass('x-hide-' + this.hideMode);
			var labelEl = this.getLabelEl();
			if (labelEl) {
				labelEl.hide();
			}
		}
	},

	setVisible: function (visible) {
		if (visible) {
			this.show();
		} else {
			this.hide();
		}
		return this;
	},

	isVisible: function () {
		return this.rendered && this.getActionEl().isVisible();
	},

	cloneConfig: function (overrides) {
		overrides = overrides || {};
		var id = overrides.id || Ext.id();
		var cfg = Ext.applyIf(overrides, this.initialConfig);
		cfg.id = id; return new this.constructor(cfg);
	},

	getXType: function () {
		return this.constructor.xtype;
	},

	isXType: function (xtype, shallow) {
		return !shallow ?
               ('/' + this.getXTypes() + '/').indexOf('/' + xtype + '/') != -1 :
                this.constructor.xtype == xtype;
	},

	getXTypes: function () {
		var tc = this.constructor;
		if (!tc.xtypes) {
			var c = [], sc = this;
			while (sc && sc.constructor.xtype) {
				c.unshift(sc.constructor.xtype);
				sc = sc.constructor.superclass;
			}
			tc.xtypeChain = c;
			tc.xtypes = c.join('/');
		}
		return tc.xtypes;
	},

	findParentBy: function (fn) {
		for (var p = this.ownerCt; (p != null) && !fn(p, this); p = p.ownerCt) {
		}
		return p || null;
	},

	findParentByType: function (xtype) {
		return typeof xtype == 'function' ?
            this.findParentBy(function (p) {
            	return p.constructor === xtype;
            }) :
            this.findParentBy(function (p) {
            	return p.constructor.xtype === xtype;
            });
	},

	mon: function (item, ename, fn, scope, opt) {
		if (!this.mons) {
			this.mons = [];
			this.on('beforedestroy', function () {
				for (var i = 0, len = this.mons.length; i < len; i++) {
					var m = this.mons[i];
					m.item.un(m.ename, m.fn, m.scope);
				}
			}, this);
		}
		this.mons.push({
			item: item, ename: ename, fn: fn, scope: scope
		});
		item.on(ename, fn, scope, opt);
	},

	initContextMenu: function () {
		if (!this.contextMenuId) {
			return;
		}
		try {
			this.contextMenu = eval(this.contextMenuId);
		} catch (e) {
			this.contextMenu = null;
		}
		if (!this.contextMenu || !this.getEl()) {
			return;
		}
		this.handleContextMenu = true;
		this.getEl().on('contextmenu', this.onContextMenuEvent, this);
	},

	onContextMenuEvent: function (e, t) {
		document.body.style.cursor = 'wait';
		this.contextMenu.trg = t;
		e.stopEvent();
		if (this.contextMenuId != this.contextMenu.proxyId) {
			this.contextMenu = eval(this.contextMenuId);
		}
		this.onHandleContextMenu(e);
		this.contextMenu.showAt(e.getPoint());
	},

	onHandleContextMenu: function (e) {
	},

	setSize: function (w, h) {

	},

	processSizeUnit: function (unit) {
		if (typeof unit == 'string') {
			var parts = Ext.Element.parseUnits(unit);
			if (parts != null) {
				if (parts.measure == '%') {
					unit = undefined;
				} else {
					unit = parseInt(parts.value);
				}
			}
		}
		return unit;
	},

	isContainerWithItems: function () {
		return this.items && this.items.length > 0 && this.isContainer !== false;
	},

	isRenderedContainerWithItems: function () {
		return this.rendered && this.items && this.items.length > 0 &&
			this.supportsCaption !== true;
	},

	isDefaultPropertyValue: function (propertyName) {
		return this[propertyName] === this.constructor.prototype[propertyName];
	}
});

Ext.reg('component', Ext.Component);

Ext.Action = function (config) {
	this.initialConfig = config;
	this.items = [];
}

Ext.Action.prototype = {
	isAction: true,

	setText: function (text) {
		this.initialConfig.text = text;
		this.callEach('setText', [text]);
	},

	getText: function () {
		return this.initialConfig.text;
	},

	setImageClass: function (cls) {
		this.initialConfig.imageCls = cls;
		this.callEach('setImageClass', [cls]);
	},

	getImageClass: function () {
		return this.initialConfig.imageCls;
	},

	setDisabled: function (v) {
		this.initialConfig.disabled = v;
		this.callEach('setDisabled', [v]);
	},

	enable: function () {
		this.setDisabled(false);
	},

	disable: function () {
		this.setDisabled(true);
	},

	isDisabled: function () {
		return this.initialConfig.disabled;
	},

	setHidden: function (v) {
		this.initialConfig.hidden = v;
		this.callEach('setVisible', [!v]);
	},

	show: function () {
		this.setHidden(false);
	},

	hide: function () {
		this.setHidden(true);
	},

	isHidden: function () {
		return this.initialConfig.hidden;
	},

	setHandler: function (fn, scope) {
		this.initialConfig.handler = fn;
		this.initialConfig.scope = scope;
		this.callEach('setHandler', [fn, scope]);
	},

	each: function (fn, scope) {
		Ext.each(this.items, fn, scope);
	},

	callEach: function (fnName, args) {
		var cs = this.items;
		for (var i = 0, len = cs.length; i < len; i++) {
			cs[i][fnName].apply(cs[i], args);
		}
	},

	addComponent: function (comp) {
		this.items.push(comp);
		comp.on('destroy', this.removeComponent, this);
	},

	removeComponent: function (comp) {
		this.items.remove(comp);
	},

	execute: function () {
		this.initialConfig.handler.apply(this.initialConfig.scope || window, arguments);
	}
};

(function () {
	Ext.Layer = function (config, existingEl) {
		config = config || {};
		var dh = Ext.DomHelper;
		var cp = config.parentEl, pel = cp ? Ext.getDom(cp) : document.body;
		if (existingEl) {
			this.dom = Ext.getDom(existingEl);
		}
		if (!this.dom) {
			var o = config.dh || { tag: "div", cls: "x-layer" };
			this.dom = dh.append(pel, o);
		}
		if (config.cls) {
			this.addClass(config.cls);
		}
		this.constrain = config.constrain !== false;
		this.visibilityMode = Ext.Element.VISIBILITY;
		if (config.id) {
			this.id = this.dom.id = config.id;
		} else {
			this.id = Ext.id(this.dom);
		}
		this.zindex = config.zindex || this.getZIndex();
		this.position("absolute", this.zindex);
		if (config.shadow) {
			this.shadowOffset = config.shadowOffset || 4;
			this.shadow = new Ext.Shadow({
				offset: this.shadowOffset
			});
		} else {
			this.shadowOffset = 0;
		}
		this.useShim = config.shim !== false && Ext.useShims;
		this.useDisplay = config.useDisplay;
		this.hide();
	};

	var supr = Ext.Element.prototype;
	var shims = [];

	Ext.extend(Ext.Layer, Ext.Element, {

		getZIndex: function () {
			return this.zindex || parseInt(this.getStyle("z-index"), 10) || 11000;
		},

		getShim: function () {
			if (!this.useShim) {
				return null;
			}
			if (this.shim) {
				return this.shim;
			}
			var shim = shims.shift();
			if (!shim) {
				shim = this.createShim();
				shim.enableDisplayMode('block');
				shim.dom.style.display = 'none';
				shim.dom.style.visibility = 'visible';
			}
			var pn = this.dom.parentNode;
			if (shim.dom.parentNode != pn) {
				pn.insertBefore(shim.dom, this.dom);
			}
			shim.setStyle('z-index', this.getZIndex() - 2);
			this.shim = shim;
			return shim;
		},

		hideShim: function () {
			if (this.shim) {
				this.shim.setDisplayed(false);
				shims.push(this.shim);
				delete this.shim;
			}
		},

		disableShadow: function () {
			if (this.shadow) {
				this.shadowDisabled = true;
				this.shadow.hide();
				this.lastShadowOffset = this.shadowOffset;
				this.shadowOffset = 0;
			}
		},

		enableShadow: function (show) {
			if (this.shadow) {
				this.shadowDisabled = false;
				this.shadowOffset = this.lastShadowOffset;
				delete this.lastShadowOffset;
				if (show) {
					this.sync(true);
				}
			}
		},

		sync: function (doShow) {
			var sw = this.shadow;
			if (!this.updating && this.isVisible() && (sw || this.useShim)) {
				var sh = this.getShim();

				var w = this.getWidth(),
                h = this.getHeight();

				var l = this.getLeft(true),
                t = this.getTop(true);

				if (sw && !this.shadowDisabled) {
					if (doShow && !sw.isVisible()) {
						sw.show(this);
					} else {
						sw.realign(l, t, w, h);
					}
					if (sh) {
						if (doShow) {
							sh.show();
						}

						var a = sw.adjusts, s = sh.dom.style;
						s.left = (Math.min(l, l + a.l)) + "px";
						s.top = (Math.min(t, t + a.t)) + "px";
						s.width = (w + a.w) + "px";
						s.height = (h + a.h) + "px";
					}
				} else if (sh) {
					if (doShow) {
						sh.show();
					}
					sh.setSize(w, h);
					sh.setLeftTop(l, t);
				}

			}
		},

		destroy: function () {
			this.hideShim();
			if (this.shadow) {
				this.shadow.hide();
			}
			this.removeAllListeners();
			Ext.removeNode(this.dom);
			Ext.Element.uncache(this.id);
		},

		remove: function () {
			this.destroy();
		},


		beginUpdate: function () {
			this.updating = true;
		},


		endUpdate: function () {
			this.updating = false;
			this.sync(true);
		},

		hideUnders: function (negOffset) {
			if (this.shadow) {
				this.shadow.hide();
			}
			this.hideShim();
		},

		constrainXY: function () {
			if (this.constrain) {
				var vw = Ext.lib.Dom.getViewWidth(),
                vh = Ext.lib.Dom.getViewHeight();
				var s = Ext.getDoc().getScroll();

				var xy = this.getXY();
				var x = xy[0], y = xy[1];
				var w = this.dom.offsetWidth + this.shadowOffset, h = this.dom.offsetHeight + this.shadowOffset;

				var moved = false;

				if ((x + w) > vw + s.left) {
					x = vw - w - this.shadowOffset;
					moved = true;
				}
				if ((y + h) > vh + s.top) {
					y = vh - h - this.shadowOffset;
					moved = true;
				}

				if (x < s.left) {
					x = s.left;
					moved = true;
				}
				if (y < s.top) {
					y = s.top;
					moved = true;
				}
				if (moved) {
					if (this.avoidY) {
						var ay = this.avoidY;
						if (y <= ay && (y + h) >= ay) {
							y = ay - h - 5;
						}
					}
					xy = [x, y];
					this.storeXY(xy);
					supr.setXY.call(this, xy);
					this.sync();
				}
			}
		},

		isVisible: function () {
			return this.visible;
		},

		showAction: function () {
			this.visible = true;
			if (this.useDisplay === true) {
				this.setDisplayed("");
			} else if (this.lastXY) {
				supr.setXY.call(this, this.lastXY);
			} else if (this.lastLT) {
				supr.setLeftTop.call(this, this.lastLT[0], this.lastLT[1]);
			}
		},

		hideAction: function () {
			this.visible = false;
			if (this.useDisplay === true) {
				this.setDisplayed(false);
			} else {
				this.setLeftTop(-10000, -10000);
			}
		},

		setVisible: function (v, a, d, c, e) {
			if (v) {
				this.showAction();
			}
			if (a && v) {
				var cb = function () {
					this.sync(true);
					if (c) {
						c();
					}
				} .createDelegate(this);
				supr.setVisible.call(this, true, true, d, cb, e);
			} else {
				if (!v) {
					this.hideUnders(true);
				}
				var cb = c;
				if (a) {
					cb = function () {
						this.hideAction();
						if (c) {
							c();
						}
					} .createDelegate(this);
				}
				supr.setVisible.call(this, v, a, d, cb, e);
				if (v) {
					this.sync(true);
				} else if (!a) {
					this.hideAction();
				}
			}
		},

		storeXY: function (xy) {
			delete this.lastLT;
			this.lastXY = xy;
		},

		storeLeftTop: function (left, top) {
			delete this.lastXY;
			this.lastLT = [left, top];
		},


		beforeFx: function () {
			this.beforeAction();
			return Ext.Layer.superclass.beforeFx.apply(this, arguments);
		},


		afterFx: function () {
			Ext.Layer.superclass.afterFx.apply(this, arguments);
			this.sync(this.isVisible());
		},


		beforeAction: function () {
			if (!this.updating && this.shadow) {
				this.shadow.hide();
			}
		},

		setLeft: function (left) {
			this.storeLeftTop(left, this.getTop(true));
			supr.setLeft.apply(this, arguments);
			this.sync();
		},

		setTop: function (top) {
			this.storeLeftTop(this.getLeft(true), top);
			supr.setTop.apply(this, arguments);
			this.sync();
		},

		setLeftTop: function (left, top) {
			this.storeLeftTop(left, top);
			supr.setLeftTop.apply(this, arguments);
			this.sync();
		},

		setXY: function (xy, a, d, c, e) {
			this.fixDisplay();
			this.beforeAction();
			this.storeXY(xy);
			var cb = this.createCB(c);
			supr.setXY.call(this, xy, a, d, cb, e);
			if (!a) {
				cb();
			}
		},

		createCB: function (c) {
			var el = this;
			return function () {
				el.constrainXY();
				el.sync(true);
				if (c) {
					c();
				}
			};
		},

		setX: function (x, a, d, c, e) {
			this.setXY([x, this.getY()], a, d, c, e);
		},

		setY: function (y, a, d, c, e) {
			this.setXY([this.getX(), y], a, d, c, e);
		},

		setSize: function (w, h, a, d, c, e) {
			this.beforeAction();
			var cb = this.createCB(c);
			supr.setSize.call(this, w, h, a, d, cb, e);
			if (!a) {
				cb();
			}
		},

		setWidth: function (w, a, d, c, e) {
			this.beforeAction();
			var cb = this.createCB(c);
			supr.setWidth.call(this, w, a, d, cb, e);
			if (!a) {
				cb();
			}
		},

		setHeight: function (h, a, d, c, e) {
			this.beforeAction();
			var cb = this.createCB(c);
			supr.setHeight.call(this, h, a, d, cb, e);
			if (!a) {
				cb();
			}
		},

		setBounds: function (x, y, w, h, a, d, c, e) {
			this.beforeAction();
			var cb = this.createCB(c);
			if (!a) {
				this.storeXY([x, y]);
				supr.setXY.call(this, [x, y]);
				supr.setSize.call(this, w, h, a, d, cb, e);
				cb();
			} else {
				supr.setBounds.call(this, x, y, w, h, a, d, cb, e);
			}
			return this;
		},

		setZIndex: function (zindex) {
			this.zindex = zindex;
			this.setStyle("z-index", zindex + 2);
			if (this.shadow) {
				this.shadow.setZIndex(zindex + 1);
			}
			if (this.shim) {
				this.shim.setStyle("z-index", zindex);
			}
		}
	});
})();

Ext.LayoutControl = Ext.extend(Ext.Component, {
	captionPosition: 'left',
	captionVerticalAlign: 'middle',
	alignedByCaption: true,
	captionPositionSupports: { left: true, top: true },
	labelElsSpace: 2,
	defaultLabelMargin: 5,
	readOnly: false,
	helpContextId: '',

	initComponent: function () {
		if (this.designMode) {
			this.readOnly = true;
		}
		Ext.LayoutControl.superclass.initComponent.call(this);
		this.addEvents(
			'resize',
			'move'
		);
	},

	forceFocus: function () {
		var ownerCt = this.ownerCt;
		if (ownerCt && ownerCt.forceFocus) {
			ownerCt.forceFocus();
		}
		if (this.hidden) {
			this.show();
		}
		this.focus();
	},

	boxReady: false,
	deferHeight: false,

	applyDesignConfig: function (designConfig) {
	},

	setHidden: function (hidden) {
		Ext.LayoutControl.superclass.setHidden.call(this, hidden);
		if (this.numberLabelEl) {
			hidden ? this.numberLabelEl.hide() : this.numberLabelEl.show();
		}
		if (this.labelEl) {
			hidden ? this.labelEl.hide() : this.labelEl.show();
		}
	},

	setSize: function (w, h) {
		w = this.processSizeUnit(w);
		h = this.processSizeUnit(h);
		if (typeof w == 'object') {
			h = w.height;
			w = w.width;
		}
		if (!this.boxReady) {
			this.width = w;
			this.height = h;
			return this;
		}

		if (this.lastSize && (w == undefined || this.lastSize.width == w) &&
				(h == undefined || this.lastSize.height == h)) {
			return this;
		}
		var lastSize = this.lastSize;
		if (!lastSize) {
			lastSize = this.lastSize = {
				width: undefined,
				height: undefined
			};
		}
		if (w !== undefined) {
			lastSize.width = w;
		}
		if (h !== undefined) {
			lastSize.height = h;
		}
		var adj = this.adjustSize(w, h);
		var aw = adj.width, ah = adj.height;
		if (aw !== undefined || ah !== undefined) {
			var rz = this.getResizeEl();
			if (!this.deferHeight && aw !== undefined && ah !== undefined) {
				rz.setSize(aw, ah);
			} else if (!this.deferHeight && ah !== undefined) {
				rz.setHeight(ah);
			} else if (aw !== undefined) {
				rz.setWidth(aw);
			}
			this.onResize(aw, ah, w, h);
			this.fireEvent('resize', this, aw, ah, w, h);
		}
		return this;
	},

	isSizeInPercent: function (size) {
		return typeof size == 'string' && size.indexOf('%') != -1;
	},

	parsePercent: function (size) {
		if (typeof size != 'string') {
			return null;
		}
		var result = NaN;
		var parts = Ext.Element.parseUnits(size);
		if (parts != null && parts.measure == '%') {
			result = parseFloat(parts.value);
		}
		return isNaN(result) ? null : result;
	},

	setWidth: function (width) {
		var result = this.setSize(width);
		return result;
	},

	setHeight: function (height) {
		var result = this.setSize(undefined, height);
		return result;
	},

	setDesignModeHeight: function (height) {
		delete this.flexHeight;
		this.height = height;
		if (this.rendered && this.ownerCt) {
			this.setSize(undefined, height);
			this.ownerCt.onContentChanged();
		}
	},

	setDesignModeWidth: function (width) {
		delete this.flexWidth;
		this.width = width;
		if (this.rendered && this.ownerCt) {
			this.setSize(width, undefined);
			this.ownerCt.onContentChanged();
		}
	},

	setAlignedByCaption: function (alignedByCaption) {
		if (typeof alignedByCaption == 'string') {
			alignedByCaption = Ext.decode(alignedByCaption);
		}
		this.alignedByCaption = alignedByCaption;
		if (!this.rendered) {
			return;
		}
		if ((this.caption !== undefined && this.captionPosition == 'left')) {
			this.ownerCt.updateControlsCaptionWidth();
		} else {
			this.ownerCt.doLayout(false);
		}
	},

	getSize: function () {
		return this.getResizeEl().getSize();
	},

	getWidth: function () {
		return this.getResizeEl().getWidth();
	},

	getHeight: function () {
		return this.getResizeEl().getHeight();
	},

	getPosition: function (local) {
		var el = this.getPositionEl();
		if (local === true) {
			return [el.getLeft(true), el.getTop(true)];
		}
		return this.xy || el.getXY();
	},

	getBox: function (local) {
		var pos = this.getPosition(local);
		var s = this.getSize();
		s.x = pos[0];
		s.y = pos[1];
		return s;
	},

	updateBox: function (box) {
		this.setSize(box.width, box.height);
		this.setPagePosition(box.x, box.y);
		return this;
	},

	getResizeEl: function () {
		return this.resizeEl || this.el;
	},

	getPositionEl: function () {
		return this.positionEl || this.el;
	},

	setPosition: function (x, y) {
		if (x && typeof x[1] == 'number') {
			y = x[1];
			x = x[0];
		}
		this.x = x;
		this.y = y;
		if (!this.boxReady) {
			return this;
		}
		var adj = this.adjustPosition(x, y);
		var ax = adj.x, ay = adj.y;

		var el = this.getPositionEl();
		if (ax !== undefined || ay !== undefined) {
			if (ax !== undefined && ay !== undefined) {
				el.setLeftTop(ax, ay);
			} else if (ax !== undefined) {
				el.setLeft(ax);
			} else if (ay !== undefined) {
				el.setTop(ay);
			}
			this.onPosition(ax, ay);
			this.fireEvent('move', this, ax, ay);
		}
		return this;
	},

	setPagePosition: function (x, y) {
		if (x && typeof x[1] == 'number') {
			y = x[1];
			x = x[0];
		}
		this.pageX = x;
		this.pageY = y;
		if (!this.boxReady) {
			return;
		}
		if (x === undefined || y === undefined) {
			return;
		}
		var p = this.getPositionEl().translatePoints(x, y);
		this.setPosition(p.left, p.top);
		return this;
	},

	onRender: function (ct, position) {
		Ext.LayoutControl.superclass.onRender.call(this, ct, position);
		if (this.resizeEl) {
			this.resizeEl = Ext.get(this.resizeEl);
		}
		if (this.positionEl) {
			this.positionEl = Ext.get(this.positionEl);
		}
	},

	afterRender: function () {
		Ext.LayoutControl.superclass.afterRender.call(this);
		this.boxReady = true;
		this.setSize(this.width, this.height);
		if (!Ext.isEmpty(this.x || this.y)) {
			this.setPosition(this.x, this.y);
		} else if (!Ext.isEmpty(this.pageX || this.pageY)) {
			this.setPagePosition(this.pageX, this.pageY);
		}
	},

	syncSize: function () {
		delete this.lastSize;
		this.setSize(this.autoWidth ? undefined : this.getResizeEl().getWidth(),
			this.autoHeight ? undefined : this.getResizeEl().getHeight());
		return this;
	},

	onResize: function (adjWidth, adjHeight, rawWidth, rawHeight) {
	},

	onPosition: function (x, y) {
	},

	adjustSize: function (w, h) {
		if (this.autoWidth) {
			w = 'auto';
		}
		if (this.autoHeight) {
			h = 'auto';
		}
		return { width: w, height: h };
	},

	adjustPosition: function (x, y) {
		return { x: x, y: y };
	},

	isCaptionRendered: function () {
		return (this.captionPosition == 'left' || this.captionPosition == 'top') ?
			Boolean(this.labelEl) : Boolean(this.rightLabelEl);
	},

	renderCaption: function () {
		this.margins.left = (this.presetMargins) ? this.presetMargins.left :
			this.ownerCt.layout.defaultMargins.left;
		this.getResizeEl().setLeftTop(0, 0);
		this.getResizeEl().removeClass('x-control-layout-item');
		this.ownerCt.layout.renderItem(this);
	},

	setCaption: function (caption) {
		this.caption = caption;
		if (!this.rendered) {
			return;
		}
		var labelEl = this.getLabelEl();
		if (caption !== undefined && !this.isCaptionRendered()) {
			this.renderCaption();
		} else if (labelEl) {
			labelEl.dom.innerHTML = caption || "";
		}
		this.updateSizeAfterCaptionChange(this.getCaptionWidth());
		if (this.captionPosition == 'left' || this.captionPosition == 'right') {
			this.ownerCt.updateControlsCaptionWidth();
		} else {
			this.ownerCt.onContentChanged();
		}
	},

	setCaptionColor: function (color) {
		this.captionColor = color;
		if (!this.rendered) {
			return;
		}
		var labelEl = this.getLabelEl();
		if (labelEl) {
			labelEl.setStyle('color', color);
		}
	},

	setCaptionWidth: function(width) {
		if (!this.labelEl) {
			return;
		}
		this.labelEl.setWidth(width);
	},

	updateSizeAfterCaptionChange: function (width) {
		if (!this.captionWrap) {
			return;
		}
		var labelElHeight;
		if (this.captionPosition !== 'top') {
			if (width !== undefined) {
				if (width == 0) {
					this.labelMargin = 0;
				}
				var controlWidth = this.captionWrap.getWidth();
				var controlElPaddingLeft = width + this.labelMargin;
				this.captionWrap.setStyle('padding-left', Ext.Element.addUnits(controlElPaddingLeft));
				if (controlWidth > 0) {
					this.captionWrap.setWidth(controlWidth);
					this.controlEl.setWidth(controlWidth - controlElPaddingLeft);
				}
				if (this.captionPosition == 'left') {
					var labelEl = this.labelEl;
					if (!labelEl) {
						labelEl = this;
					}
					labelElHeight = labelEl.getHeight();
					var controlElHeight = this.controlEl.getHeight();
					var maxHeight = Math.max(labelElHeight, controlElHeight);
					if (maxHeight !== this.captionWrap.getHeight()) {
						this.captionWrap.setHeight(maxHeight);
					}

				}
				if (this.captionPosition == 'left') {
					this.setCaptionVerticalAlign(this.captionVerticalAlign);
				}
			}
		} else {
			if (width != undefined) {
				this.setCaptionWidth(width);
				var controlElWidth = width;
				this.controlEl.setWidth(controlElWidth);
				this.captionWrap.setWidth(width);
			}
			labelElHeight = (this.labelEl) ? this.labelEl.getHeight() : 0;
			var controlElPaddingTop = labelElHeight + this.labelMargin;
			if (controlElPaddingTop != this.captionWrap.getPadding('t')) {
				this.captionWrap.setStyle('padding-top', this.captionWrap.addUnits(controlElPaddingTop));
		}
		}
	},

	getCaptionTextWidth: function() {
		return this.labelEl ? this.labelEl.getTextWidth() : 0;
	},

	getCaptionWidth: function () {
		return (this.labelEl) ? this.labelEl.getWidth() : 0;
	},

	getRawCaptionTextWidth: function () {
		return (this.caption != undefined) ? this.getRawTextWidth(this.caption) : 0;
	},

	getRawTextWidth: function (text) {
		if (text == undefined) {
			return;
		}
		var el = Ext.getRawTextWidthEl;
		if (!el) {
			el = Ext.get(document.createElement('div'));
			Ext.getRawTextWidthEl = el;
			var styles = { fontFamily: 'tahoma', fontSize: '11px' };
			el.applyStyles(styles);
		}
		el.dom.innerHTML = text;
		return el.getTextWidth();
	},

	setCaptionColor: function (color) {
		var labelEl = this.getLabelEl();
		if (!labelEl) {
			return;
		}
		if (this.numberLabelEl) {
			this.numberLabelEl.dom.style.color = color || '#000';
		}
		labelEl.dom.style.color = color || '#000';
	},

	setCaptionPosition: function (position) {
		position = position.toLowerCase();
		this.captionPosition = position;
		if (!this.rendered) {
			return;
		}
		if (this.designMode && this.captionWrap) {
			if (this.captionPosition == 'top') {
				var controlWidth = this.getWidth();
				this.captionWrap.setStyle('padding-left', Ext.Element.addUnits(0));
				this.labelEl.setStyle('top', Ext.Element.addUnits(0));
				this.updateSizeAfterCaptionChange(controlWidth);
			} else if (this.captionPosition == 'left') {
				this.captionWrap.setStyle('padding-top', Ext.Element.addUnits(0));
			}
			this.ownerCt.updateControlsCaptionWidth();
		}
	},

	isCaptionPositionSupports: function (position) {
		return this.captionPositionSupports[position] == true;
	},

	getCaptionPositionOffset: function () {
		if (this.captionPosition == 'left' && this.captionVerticalAlign == 'middle') {
			return -1;
		}
		return 0;
	},

	setCaptionVerticalAlign: function (captionVerticalAlign) {
		if (!captionVerticalAlign) {
			return;
		}
		captionVerticalAlign = captionVerticalAlign.toLowerCase();
		this.captionVerticalAlign = captionVerticalAlign;
		if (!this.rendered || this.captionPosition == 'top' || (this.captionPosition == 'right')) {
			return;
		}
		var labelEl;
		if (!Ext.isEmpty(this.caption) && this.labelEl && this.captionPosition == 'left' &&
				this.labelEl.getHeight() > 0) {
			labelEl = this.labelEl;
		}
		if (!labelEl) {
			return;
		}
		var controlElHeight = this.controlEl.getHeight();
		var labelElHeight = labelEl.getHeight();
		if (controlElHeight == labelElHeight) {
			return;
		}
		var topPosition = 0;
		var topPositionOffset = 0;
		var alignEl
		var maxHeightEl;
		var maxHeight;
		var alignElHeight;
		if (labelElHeight > controlElHeight) {
			topPositionOffset = 0;
			alignEl = this.controlEl;
			maxHeightEl = labelEl;
			maxHeight = labelElHeight;
			alignElHeight = controlElHeight;
		} else {
			topPositionOffset = this.getCaptionPositionOffset();
			alignEl = labelEl;
			maxHeightEl = this.controlEl;
			maxHeight = controlElHeight;
			alignElHeight = labelElHeight;
		}
		switch (captionVerticalAlign) {
			case 'middle':
				topPosition = (maxHeight - alignElHeight) / 2;
				break;
			case 'bottom':
				topPosition = maxHeight - alignElHeight;
				break;
		}
		alignEl.setStyle('top', Ext.Element.addUnits(topPosition + topPositionOffset));
		maxHeightEl.setStyle('top', Ext.Element.addUnits(0));
	},

	setMargins: function (margins) {
		if (this.rendered) {
			var ownerCt = this.ownerCt;
			if (ownerCt && ownerCt.layout) {
				var isMarginsEmpty = Ext.isEmpty(margins);
				if (isMarginsEmpty) {
					delete this.presetMargins;
					this.margins = Ext.apply({}, ownerCt.layout.defaultMargins);
				} else {
					margins = ownerCt.layout.parseMargins(margins);
					this.margins = margins;
					this.presetMargins = Ext.apply({}, margins);
				}
				ownerCt.onContentChanged();
			}
		} else {
			this.margins = margins;
		}
	},

	setProductEdition: function (productEdition) {
		this.productEdition = productEdition;
	},
	
	setHelpContextId: function (helpContextId) {
		this.helpContextId = helpContextId;
	},

	onDestroy: function () {
		var resizeEl = this.getResizeEl();
		if (resizeEl) {
			resizeEl.removeAllListeners();
			resizeEl.remove();
		}
		if (this.numberLabelEl) {
			this.numberLabelEl.removeAllListeners();
			this.numberLabelEl.remove();
		}
		Ext.LayoutControl.superclass.onDestroy.call(this);
	}

});

Ext.reg('layoutcontrol', Ext.LayoutControl);

Ext.Spacer = Ext.extend(Ext.LayoutControl, {
	xtype: 'spacer',
	autoEl: 'div',
	size: 50,
	stripeSize: 3,
	stripeVisible: false,

	setStripeVisible: function (stripeVisible) {
		this.stripeVisible = stripeVisible;
		var size;
		if (stripeVisible) {
			if (!this.el.hasClass('x-spacer-strip')) {
				this.size = this.stripeSize;
				this.el.addClass('x-spacer-strip');
			}
		} else {
			this.el.removeClass('x-spacer-strip');
		}
		this.actualizeSize(this.ownerCt.direction);
		if (this.designMode) {
			this.ownerCt.onContentChanged();
		}
	},

	afterRender: function () {
		var stripeVisible = this.stripeVisible;
		if (stripeVisible) {
			this.size = this.stripeSize;
			this.el.addClass('x-spacer-strip');
		}
		Ext.Spacer.superclass.afterRender.call(this);
		var ownerCt = this.ownerCt;
		if (ownerCt) {
			ownerCt.on('directionchange', this.actualizeSize, this);
			this.actualizeSize(ownerCt.direction);
		}
	},

	switchDirection: function (direction) {
		if (this.stripeVisible) {
			this.size = this.stripeSize;
		}
		this.actualizeSize(direction);
	},

	actualizeSize: function (direction) {
		var width;
		var height;
		if (direction === 'vertical') {
			width = '100%';
			height = this.size;
		} else if (direction === 'horizontal') {
			width = this.size;
			height = '100%';
		}
		this.width = width;
		this.height = height;
		this.setSize(width, height);
	},

	setDesignModeSize: function (size) {
		this.size = size;
		var direction = this.ownerCt.direction;
		if (direction === 'vertical') {
			this.width = '100%';
			this.setDesignModeHeight(size);
		} else if (direction === 'horizontal') {
			this.height = '100%';
			this.setDesignModeWidth(size);
		}
	}
});
Ext.reg('spacer', Ext.Spacer);

Ext.SplitBar = function (dragElement, resizingElement, orientation, placement, existingProxy) {
	this.el = Ext.get(dragElement, true);
	this.el.dom.unselectable = "on";
	this.resizingEl = Ext.get(resizingElement, true);
	this.orientation = orientation || Ext.SplitBar.HORIZONTAL;
	this.minSize = 0;
	this.maxSize = 2000;
	this.animate = false;
	this.useShim = false;
	this.shim = null;
	if (!existingProxy) {
		this.proxy = Ext.SplitBar.createProxy(this.orientation);
	} else {
		this.proxy = Ext.get(existingProxy).dom;
	}
	this.dd = new Ext.dd.DDProxy(this.el.dom.id, "XSplitBars", { dragElId: this.proxy.id });
	this.dd.b4StartDrag = this.onStartProxyDrag.createDelegate(this);
	this.dd.endDrag = this.onEndProxyDrag.createDelegate(this);
	this.dragSpecs = {};
	this.adapter = new Ext.SplitBar.BasicLayoutAdapter();
	this.adapter.init(this);
	if (this.orientation == Ext.SplitBar.HORIZONTAL) {
		this.placement = placement || (this.el.getX() > this.resizingEl.getX() ? Ext.SplitBar.LEFT : Ext.SplitBar.RIGHT);
		this.el.addClass("x-splitbar-h");
	} else {
		this.placement = placement || (this.el.getY() > this.resizingEl.getY() ? Ext.SplitBar.TOP : Ext.SplitBar.BOTTOM);
		this.el.addClass("x-splitbar-v");
	}

	this.addEvents(
		"resize",
		"moved",
		"beforeresize",
		"beforeapply"
	);
	Ext.SplitBar.superclass.constructor.call(this);
};

Ext.extend(Ext.SplitBar, Ext.util.Observable, {
	onStartProxyDrag: function (x, y) {
		this.fireEvent("beforeresize", this);
		this.overlay =
			Ext.DomHelper.append(document.body, { cls: "x-drag-overlay", html: "&#160;" }, true);
		this.overlay.unselectable();
		this.overlay.setSize(Ext.lib.Dom.getViewWidth(true), Ext.lib.Dom.getViewHeight(true));
		this.overlay.show();
		Ext.get(this.proxy).setDisplayed("block");
		var size = this.adapter.getElementSize(this);
		this.activeMinSize = this.getMinimumSize(); ;
		this.activeMaxSize = this.getMaximumSize(); ;
		var c1 = size - this.activeMinSize;
		var c2 = Math.max(this.activeMaxSize - size, 0);
		if (this.orientation == Ext.SplitBar.HORIZONTAL) {
			this.dd.resetConstraints();
			this.dd.setXConstraint(
				this.placement == Ext.SplitBar.LEFT ? c1 : c2,
				this.placement == Ext.SplitBar.LEFT ? c2 : c1
			);
			this.dd.setYConstraint(0, 0);
		} else {
			this.dd.resetConstraints();
			this.dd.setXConstraint(0, 0);
			this.dd.setYConstraint(
				this.placement == Ext.SplitBar.TOP ? c1 : c2,
				this.placement == Ext.SplitBar.TOP ? c2 : c1
			);
		}
		this.dragSpecs.startSize = size;
		this.dragSpecs.startPoint = [x, y];
		Ext.dd.DDProxy.prototype.b4StartDrag.call(this.dd, x, y);
	},

	onEndProxyDrag: function (e) {
		Ext.get(this.proxy).setDisplayed(false);
		var endPoint = Ext.lib.Event.getXY(e);
		if (this.overlay) {
			this.overlay.remove();
			delete this.overlay;
		}
		var newSize;
		if (this.orientation == Ext.SplitBar.HORIZONTAL) {
			newSize = this.dragSpecs.startSize +
				(this.placement == Ext.SplitBar.LEFT ?
					endPoint[0] - this.dragSpecs.startPoint[0] :
					this.dragSpecs.startPoint[0] - endPoint[0]
				);
		} else {
			newSize = this.dragSpecs.startSize +
				(this.placement == Ext.SplitBar.TOP ?
					endPoint[1] - this.dragSpecs.startPoint[1] :
					this.dragSpecs.startPoint[1] - endPoint[1]
				);
		}
		newSize = Math.min(Math.max(newSize, this.activeMinSize), this.activeMaxSize);
		if (newSize != this.dragSpecs.startSize) {
			if (this.fireEvent('beforeapply', this, newSize) !== false) {
				this.adapter.setElementSize(this, newSize);
				this.fireEvent("moved", this, newSize);
				this.fireEvent("resize", this, newSize);
			}
		}
	},

	getAdapter: function () {
		return this.adapter;
	},

	setAdapter: function (adapter) {
		this.adapter = adapter;
		this.adapter.init(this);
	},

	getMinimumSize: function () {
		return this.minSize;
	},

	setMinimumSize: function (minSize) {
		this.minSize = minSize;
	},

	getMaximumSize: function () {
		return this.maxSize;
	},

	setMaximumSize: function (maxSize) {
		this.maxSize = maxSize;
	},

	setCurrentSize: function (size) {
		var oldAnimate = this.animate;
		this.animate = false;
		this.adapter.setElementSize(this, size);
		this.animate = oldAnimate;
	},

	destroy: function (removeEl) {
		if (this.shim) {
			this.shim.remove();
		}
		this.dd.unreg();
		Ext.removeNode(this.proxy);
		if (removeEl) {
			this.el.remove();
		}
	}
});

Ext.SplitBar.createProxy = function (dir) {
	var proxy = new Ext.Element(document.createElement("div"));
	proxy.unselectable();
	var cls = 'x-splitbar-proxy';
	proxy.addClass(cls + ' ' + (dir == Ext.SplitBar.HORIZONTAL ? cls + '-h' : cls + '-v'));
	document.body.appendChild(proxy.dom);
	return proxy.dom;
};

Ext.SplitBar.BasicLayoutAdapter = function () {
};

Ext.SplitBar.BasicLayoutAdapter.prototype = {

	init: function (s) {
	},

	getElementSize: function (s) {
		if (s.orientation == Ext.SplitBar.HORIZONTAL) {
			return s.resizingEl.getWidth();
		} else {
			return s.resizingEl.getHeight();
		}
	},

	setElementSize: function (s, newSize, onComplete) {
		if (s.orientation == Ext.SplitBar.HORIZONTAL) {
			if (!s.animate) {
				s.resizingEl.setWidth(newSize);
				if (onComplete) {
					onComplete(s, newSize);
				}
			} else {
				s.resizingEl.setWidth(newSize, true, .1, onComplete, 'easeOut');
			}
		} else {

			if (!s.animate) {
				s.resizingEl.setHeight(newSize);
				if (onComplete) {
					onComplete(s, newSize);
				}
			} else {
				s.resizingEl.setHeight(newSize, true, .1, onComplete, 'easeOut');
			}
		}
	}
};

Ext.SplitBar.AbsoluteLayoutAdapter = function (container) {
	this.basic = new Ext.SplitBar.BasicLayoutAdapter();
	this.container = Ext.get(container);
};

Ext.SplitBar.AbsoluteLayoutAdapter.prototype = {
	init: function (s) {
		this.basic.init(s);
	},

	getElementSize: function (s) {
		return this.basic.getElementSize(s);
	},

	setElementSize: function (s, newSize, onComplete) {
		this.basic.setElementSize(s, newSize, this.moveSplitter.createDelegate(this, [s]));
	},

	moveSplitter: function (s) {
		var yes = Ext.SplitBar;
		switch (s.placement) {
			case yes.LEFT:
				s.el.setX(s.resizingEl.getRight());
				break;
			case yes.RIGHT:
				s.el.setStyle("right", (this.container.getWidth() - s.resizingEl.getLeft()) + "px");
				break;
			case yes.TOP:
				s.el.setY(s.resizingEl.getBottom());
				break;
			case yes.BOTTOM:
				s.el.setY(s.resizingEl.getTop() - s.el.getHeight());
				break;
		}
	}
};

Ext.SplitBar.VERTICAL = 1;

Ext.SplitBar.HORIZONTAL = 2;

Ext.SplitBar.LEFT = 1;

Ext.SplitBar.RIGHT = 2;

Ext.SplitBar.TOP = 3;

Ext.SplitBar.BOTTOM = 4;

Ext.Container = Ext.extend(Ext.LayoutControl, {
	autoDestroy: true,
	defaultType: 'panel',
	collapseMode: 'auto',
	isCollapsible: false,
	collapsed: false,

	initComponent: function () {
		Ext.Container.superclass.initComponent.call(this);

		this.addEvents(
			'afterlayout',
			'beforeadd',
			'beforeremove',
			'add',
			'remove',
			'contentchanged'
		);
		this.on('contentchanged', this.onContentChanged, this);
		var items = this.items;
		if (items) {
			delete this.items;
			if (Ext.isArray(items)) {
				this.add.apply(this, items);
			} else {
				this.add(items);
			}
		}
	},

	initItems: function () {
		if (!this.items) {
			this.items = new Ext.util.MixedCollection(false, this.getComponentId);
			if (!this.enabled) {
				this.setEnabled(false);
			}
			this.getLayout();
		}
	},

	forceFocus: function () {
		var ownerCt = this.ownerCt;
		if (ownerCt && ownerCt.forceFocus) {
			ownerCt.forceFocus();
		}
		if (this.collapsed) {
			this.expand();
		}
	},

	getAlignGroupContainer: function () {
		if (this.startNewAlignGroup) {
			return this;
		}
		var ownerCt = this.ownerCt;
		if (!ownerCt) {
			return this;
		}
		return ownerCt.getAlignGroupContainer();
	},

	setLayout: function (layout) {
		if (this.layout && this.layout != layout) {
			this.layout.setContainer(null);
		}
		this.initItems();
		this.layout = layout;
		layout.setContainer(this);
	},

	render: function () {
		Ext.Container.superclass.render.apply(this, arguments);
		if (this.layout) {
			if (typeof this.layout == 'string') {
				this.layout = new Ext.Container.LAYOUTS[this.layout.toLowerCase()](this.layoutConfig);
			}
			this.setLayout(this.layout);

			if (this.activeItem !== undefined) {
				var item = this.activeItem;
				delete this.activeItem;
				this.layout.setActiveItem(item);
				return;
			}
		}
		if (!this.ownerCt) {
			this.calculateControlsCaptionWidth();
		}
		if (!this.ownerCt || this.autoLayout) {
			if (this.isViewPort === true && !this.dontShowLoadMask) {
				var loadMask = new Ext.LoadMask(this.el, { extCls: 'blue', fitToElement: true });
				loadMask.show();
			}
			if (!this.ownerCt || this.autoLayout) {
				this.doLayout(true, true);
			}
			if (loadMask) {
				loadMask.hide();
				loadMask.destroy();
			}
		}
		if (this.monitorResize === true) {
			Ext.EventManager.onWindowResize(this.onWindowResize, this, [false]);
		}
		this.hiddenFieldCollapsedName = this.id + '_Collapsed';
		if (!this.isDefaultPropertyValue('collapsed')) {
			this.createHiddenFieldCollapsed();
			this.hiddenFieldCollapsedEl.dom.value = this.collapsed;
		}
	},

	onWindowResize: function () {
		this.doLayout(false);
	},

	afterRender: function () {
		if (this.collapsed) {
			this.defineCollapsedDisplayStyle();
		}
		Ext.Container.superclass.afterRender.call(this);
		this.setEdges(this.edges);
	},

	defineCollapsedDisplayStyle: function () {
		var isVerticalDirection = (this.ownerCt.direction == 'vertical');
		if (isVerticalDirection) {
			this.el.addClass(this.collapsedCls);
			this.expandedHeight = this.height;
			this.height = this.getCollapsedStyleHeight();
		} else {
			this.expandedWidth = this.width;
			this.width = 0;
		}
	},

	setEdges: function (edgesValue) {
		if (edgesValue && (edgesValue.indexOf("1") != -1)) {
			var resizeEl = this.getResizeEl();
			resizeEl.addClass("x-container-border");
			var edges = edgesValue.split(" ");
			var style = resizeEl.dom.style;
			style.borderTopStyle = (edges[0] == 1 ? 'solid' : 'none');
			style.borderRightStyle = (edges[1] == 1 ? 'solid' : 'none');
			style.borderBottomStyle = (edges[2] == 1 ? 'solid' : 'none');
			style.borderLeftStyle = (edges[3] == 1 ? 'solid' : 'none');
		}
	},

	onContentChanged: function (forceOwnerNotification) {
		if (this.contentUpdating === true) {
			this.needOnContentChanged = true;
			return;
		}
		if (this.ownerCt && (forceOwnerNotification === true || this.fitHeightByContent === true)) {
			this.ownerCt.fireEvent('contentchanged', this);
		} else {
			this.doLayout(false);
		}
	},

	getContainerCaptionWidth: function () {
		var captionWidth = parseInt(this.captionWidth);
		return isNaN(captionWidth) ? undefined : captionWidth;
	},

	getContainerMaxCaptionWidth: function () {
		var maxCaptionWidth = parseInt(this.maxCaptionWidth);
		return isNaN(maxCaptionWidth) ? undefined : maxCaptionWidth;
	},

	calculateControlsCaptionWidth: function () {
		if (!this.isContainerWithItems()) {
			return;
		}
		var maxRawCaptionTextWidth = this.getMaxItemsRawCaptionTextWidth();
		if (maxRawCaptionTextWidth > 0) {
			this.captionWidth = maxRawCaptionTextWidth;
			this.setCaptionWidth(maxRawCaptionTextWidth);
		}
	},

	updateControlsCaptionWidth: function () {
		if (this.contentUpdating === true) {
			this.needUpdateControlsCaptionWidth = true;
			return;
		}
		if ((this.startNewAlignGroup === true) || !this.ownerCt) {
			this.calculateControlsCaptionWidth();
			this.doLayout();
		} else {
			this.ownerCt.updateControlsCaptionWidth();
		}
	},

	getMaxItemsRawCaptionTextWidth: function () {
		var items = this.items.items;
		var rawCaptionTextWidth = 0;
		var maxItemRawCaptionTextWidth = 0;
		var maxContainerCaptionWidth = 0;
		if (this instanceof Terrasoft.ControlLayout) {
			maxContainerCaptionWidth = this.getContainerMaxCaptionWidth();
		}
		for (var i = 0; i < items.length; i++) {
			var item = items[i];
			if (item.hidden == true) {
				continue;
			}
			if ((this.direction === 'vertical' || i == 0) && item.startNewAlignGroup !== true) {
				if (item.isContainerWithItems()) {
					maxItemRawCaptionTextWidth = item.getMaxItemsRawCaptionTextWidth();
				} else if (item.captionPosition === 'left' && item.supportsCaption === true) {
					maxItemRawCaptionTextWidth = item.alignedByCaption == true ? item.getRawCaptionTextWidth() : 0;
				}
				if (maxItemRawCaptionTextWidth > rawCaptionTextWidth) {
					rawCaptionTextWidth = maxItemRawCaptionTextWidth;
				}
			} else if (item.isContainerWithItems()) {
				item.calculateControlsCaptionWidth();
			}
			if (maxContainerCaptionWidth > 0 && rawCaptionTextWidth > maxContainerCaptionWidth) {
				rawCaptionTextWidth = maxContainerCaptionWidth;
		}
		}
		return rawCaptionTextWidth;
	},

	setCaptionWidth: function(maxCaptionWidth) {
		this.captionWidth = maxCaptionWidth;
		var items = this.items.items;
		for (var i = 0; i < items.length; i++) {
			var item = items[i];
			if ((this.direction === 'vertical' || i == 0) && item.startNewAlignGroup !== true) {
				if (item instanceof Terrasoft.ControlLayout) {
					item.captionWidth = maxCaptionWidth;
				}
				if (item.isContainerWithItems()) {
					item.setCaptionWidth(maxCaptionWidth);
				}
			}
		}
	},

	getCollapseMode: function () {
		return this.collapseMode;
	},

	getLayoutTarget: function () {
		return this.el;
	},

	getComponentId: function (comp) {
		return comp.itemId || comp.id;
	},

	add: function (comp, force) {
		if (!this.items) {
			this.initItems();
		}
		var a = arguments, len = a.length;
		if (len > 1) {
			for (var i = 0; i < len; i++) {
				var argument = a[i];
				if (typeof argument !== "boolean") {
					this.add(argument);
				}
			}
			return;
		}
		var c = this.lookupComponent(this.applyDefaults(comp));
		var pos = this.items.length;
		if ((force === true || this.fireEvent('beforeadd', this, c, pos) !== false)
				&& this.onBeforeAdd(c) !== false) {
			this.items.add(c);
			c.ownerCt = this;
			this.fireEvent('add', this, c, pos);
		}
		return c;
	},

	insert: function (index, comp, force) {
		if (!this.items) {
			this.initItems();
		}
		var a = arguments, len = a.length;
		if (len > 2) {
			for (var i = len - 1; i >= 1; --i) {
				var argument = a[i];
				if (typeof argument !== "boolean") {
					this.insert(index, argument);
				}
			}
			return;
		}
		var c = this.lookupComponent(this.applyDefaults(comp));

		if (c.ownerCt == this && this.items.indexOf(c) < index) {
			--index;
		}

		if ((force === true || this.fireEvent('beforeadd', this, c, index) !== false)
				&& this.onBeforeAdd(c) !== false) {
			this.items.insert(index, c);
			c.ownerCt = this;
			this.fireEvent('add', this, c, index);
		}
		return c;
	},

	applyDefaults: function (c) {
		if (this.defaults) {
			if (typeof c == 'string') {
				c = Ext.ComponentMgr.get(c);
				Ext.apply(c, this.defaults);
			} else if (!c.events) {
				Ext.applyIf(c, this.defaults);
			} else {
				Ext.apply(c, this.defaults);
			}
		}
		return c;
	},

	onBeforeAdd: function (item) {
		if (item.ownerCt) {
			item.ownerCt.remove(item, false);
		}
		if (this.hideBorders === true) {
			item.border = (item.border === true);
		}
	},

	remove: function (comp, autoDestroy, force) {
		var c = this.getComponent(comp);
		if (c && (force === true || this.fireEvent('beforeremove', this, c) !== false)) {
			this.items.remove(c);
			delete c.ownerCt;
			if (autoDestroy === true || (autoDestroy !== false && this.autoDestroy)) {
				c.destroy();
			}
			if (this.layout && this.layout.activeItem == c) {
				delete this.layout.activeItem;
			}
			this.fireEvent('remove', this, c);
		}
		return c;
	},

	getComponent: function (comp) {
		if (typeof comp == 'object') {
			return comp;
		}
		return this.items.get(comp);
	},

	lookupComponent: function (comp) {
		if (typeof comp == 'string') {
			return Ext.ComponentMgr.get(comp);
		} else if (!comp.events) {
			return this.createComponent(comp);
		}
		return comp;
	},

	createComponent: function (config) {
		return Ext.ComponentMgr.create(config, this.defaultType);
	},

	doLayout: function (deepLayout, isFirstLayout) {
		if (!this.ownerCt) {
			var guid = new Ext.ux.GUID();
			var counterName = 'doLayout ' + this.id + ' ' + guid;
			Terrasoft.PerformanceCounterManager.startCounter(counterName);
		}
		if (this.contentUpdating === true) {
			this['need' + (deepLayout === false ? 'Shallow' : 'Deep') + 'DoLayout'] = true;
			return;
		}
		if (this.rendered && this.layout) {
			this.layout.isFirstLayout = isFirstLayout;
			this.layout.layout();
		}
		if (deepLayout !== false && this.items) {
			var cs = this.items.items;
			for (var i = 0, len = cs.length; i < len; i++) {
				var c = cs[i];
				if (c.doLayout) {
					c.doLayout();
				}
			}
		}
		if (!this.ownerCt) {
			Terrasoft.PerformanceCounterManager.stopCounter(counterName);
		}
	},

	getLayout: function () {
		if (!this.layout) {
			var layout = new Ext.layout.ContainerLayout(this.layoutConfig);
			this.setLayout(layout);
		}
		return this.layout;
	},

	beforeDestroy: function () {
		if (this.items) {
			Ext.destroy.apply(Ext, this.items.items);
		}
		if (this.monitorResize) {
			Ext.EventManager.removeResizeListener(this.doLayout, this);
		}
		if (this.layout && this.layout.destroy) {
			this.layout.destroy();
		}
		Ext.Container.superclass.beforeDestroy.call(this);
	},

	bubble: function (fn, scope, args) {
		var p = this;
		while (p) {
			if (fn.apply(scope || p, args || [p]) === false) {
				break;
			}
			p = p.ownerCt;
		}
	},

	cascade: function (fn, scope, args) {
		if (fn.apply(scope || this, args || [this]) !== false) {
			if (this.items) {
				var cs = this.items.items;
				for (var i = 0, len = cs.length; i < len; i++) {
					if (cs[i].cascade) {
						cs[i].cascade(fn, scope, args);
					} else {
						fn.apply(scope || cs[i], args || [cs[i]]);
					}
				}
			}
		}
	},

	findById: function (id, customNaming) {
		if (!customNaming) {
			id = this.id + '_' + id;
		}
		var m, ct = this;
		this.cascade(function (c) {
			if (ct != c && c.id === id) {
				m = c;
				return false;
			}
		});
		return m || null;
	},

	findByType: function (xtype) {
		return typeof xtype == 'function' ?
            this.findBy(function (c) {
            	return c.constructor === xtype;
            }) :
            this.findBy(function (c) {
            	return c.constructor.xtype === xtype;
            });
	},

	find: function (prop, value) {
		return this.findBy(function (c) {
			return c[prop] === value;
		});
	},

	findBy: function (fn, scope) {
		var m = [], ct = this;
		this.cascade(function (c) {
			if (ct != c && fn.call(scope || c, c, ct) === true) {
				m.push(c);
			}
		});
		return m;
	},

	removeControl: function (item) {
		if (item.items && item.isContainer !== false) {
			item.removeControls();
		}
		var isItemWithCaptionLeftPosition =
			(item.caption !== undefined && item.captionPosition == 'left');
		this.remove(item, true, true);
		if (this.designMode) {
			if (isItemWithCaptionLeftPosition) {
				this.updateControlsCaptionWidth();
			} else {
				this.onContentChanged();
			}
		}
	},

	removeControls: function () {
		if (this.items && this.items.length > 0) {
			for (var i = this.items.length - 1; i >= 0; i--) {
				var item = this.items.items[i];
				this.removeControl(item);
			}
		}
	},

	collapse: function () {
		if (this.collapsed || this.fireEvent('beforecollapse', this) === false) {
			return;
		}
		this.onCollapse();
	},

	onCollapse: function () {
		this.afterCollapse();
		var ownerCt = this.ownerCt;
		var isVerticalDirection = (ownerCt.direction == 'vertical');
		var requiredLayout = true;
		if (!isVerticalDirection && this.splitterMoving) {
			this.expandedWidth = this.getWidth();
			this.setWidth(0);
		} else {
			var height = this.height;
			this.expandedHeight = this.getHeight();
			this.setHeight(this.getCollapsedStyleHeight());
			if (ownerCt.itemsHeightAjusting) {
				requiredLayout = false;
			}
			if (this.isSizeInPercent(height) === true) {
				this.expandedHeight = height;
				delete this.height;
			}
		}
		this.onContentChanged();
		if (this.flexHeight || this.flexWidth) {
			ownerCt.layout.clearFlex(this);
		}
		if (!requiredLayout) {
			return;
		}
		var layout = ownerCt.layout;
		layout.layout();
	},

	afterCollapse: function () {
		this.setCollapsed(true);
		this.el.addClass(this.collapsedCls);
		this.fireEvent('collapse', this);
	},
	
	createHiddenFieldCollapsed: function () {
		if (this.hiddenFieldCollapsedEl) {
			return;
		}
		var formEl = Ext.get(document.forms[0]);
		this.hiddenFieldCollapsedEl = Ext.get(formEl.createChild({
			tag: 'input',
			type: 'hidden',
			name: this.hiddenFieldCollapsedName,
			id: this.hiddenFieldCollapsedName
		}, undefined, true));
	},

	setCollapsed: function (collapsed) {
		this.collapsed = collapsed;
		this.setProfileData('collapsed', collapsed);
		if (!this.rendered) {
			return;
		}
		this.createHiddenFieldCollapsed();
		this.hiddenFieldCollapsedEl.dom.value = this.collapsed;
	},

	expand: function () {
		if (!this.collapsed || this.fireEvent('beforeexpand', this) === false) {
			return;
		}
		this.el.removeClass(this.collapsedCls);
		this.onExpand();
		return this;
	},

	onExpand: function () {
		this.afterExpand();
		var expandedHeight = this.expandedHeight;
		var expandedWidth = this.expandedWidth;
		if (expandedHeight == undefined && expandedWidth == undefined) {
			return;
		}
		var ownerCt = this.ownerCt;
		if (expandedHeight !== undefined) {
			ownerCt.adjustItemsHeight(this);
			if (this.fitHeightByContent !== true) {
				var flexHeight = this.parsePercent(expandedHeight);
				if (flexHeight !== null) {
					this.height = expandedHeight;
					this.flexHeight = flexHeight;
				} else {
					this.setHeight(expandedHeight);
				}
			}
			delete this.expandedHeight;
		} else {
			if (expandedWidth !== undefined) {
				var flexWidth = this.parsePercent(expandedWidth);
				if (flexWidth != null) {
					this.flexWidth = flexWidth;
					this.width = expandedWidth;
				} else {
					this.setWidth(expandedWidth);
				}
				delete this.expandedWidth;
			}
		}
		ownerCt.layout.layout();
	},

	afterExpand: function () {
		this.setCollapsed(false);
		this.fireEvent('expand', this);
	},

	toggleCollapse: function () {
		this[this.collapsed ? 'expand' : 'collapse']();
		return this;
	},

	selectControl: function (control, force) {
		if (control == Ext.lastSelectedControl) {
			return;
		}
		if (force !== true &&
				this.fireEvent('beforecontrolselect', this.id, control.id) === false) {
			return false;
		}
		var controlSelectionEl = this.showControlSelection(control);
		if (control.dragSourceDD) {
			control.dragSourceDD.setOuterHandleElId(controlSelectionEl.id);
		}
		Ext.getDoc().on('mousedown', this.onDocMouseDown, control, controlSelectionEl);
		if (Ext.lastSelectedControl) {
			Ext.lastSelectedControl.un('move', this.onItemMove, Ext.lastSelectedControl);
		}
		control.on('move', this.onItemMove, control);
		this.fireEvent('controlselect', this.id, control.id);
		Ext.lastSelectedControl = control;
	},

	getControlByPoint: function (point) {
		var items = this.layout.getItems(this);
		var item;
		var control = this;
		for (var i = 0; i < items.length; i++) {
			item = items[i];
			if (item == undefined) {
				continue;
			}
			itemRegion = item.getResizeEl().getRegion();
			if (itemRegion.contains(point)) {
				if (item.getControlByPoint && item.items && item.items.length > 0) {
					control = item.getControlByPoint(point);
					break;
				} else {
					control = item;
					break;
				}
			}
		}
		return control;
	},

	onItemMouseDown: function (e) {
		if (e.browserEvent.eventCanceled === true) {
			return;
		}
		if (e.button == 0 && this.ownerCt) {
			e.stopPropagation();
			this.ownerCt.selectControl(this);
		}
	},

	onDocMouseDown: function (e, target, controlSelectionEl) {
		if (e.button == 0) {
			var control;
			if (this.getControlByPoint && target == controlSelectionEl.dom && this.layout) {
				var xy = Ext.lib.Event.getXY(e);
				var pt = new Ext.lib.Point(xy[0], xy[1]);
				control = this.getControlByPoint(pt);

			}
			if (this.el && !this.getResizeEl().contains(target) && control != this &&
					target != controlSelectionEl.dom) {
				if (this.dragSourceDD) {
					this.dragSourceDD.removeOuterHandleElId(controlSelectionEl.id);
				}
				Ext.lastSelectedControl = null;
				this.ownerCt.hideControlSelection(controlSelectionEl);
				Ext.getDoc().un('mousedown', this.ownerCt.onDocMouseDown, this);
			}
			if (control != undefined) {
				this.ownerCt.selectControl(control);
			}
		}
	},

	onItemMove: function () {
		if (this.designMode && Ext.lastSelectedControl == this) {
			this.ownerCt.showControlSelection(this);
		}
	},

	showControlSelection: function (control) {
		var controlSelectionEl = Ext.designModeControlSelectionEl;
		if (!controlSelectionEl) {
			var body = Ext.getBody();
			var style = 'position:absolute;z-index:10000;display:none;';
			controlSelectionEl = body.createChild({
				id: 'designModeControlSelection',
				style: style
			});
			controlSelectionEl.visibilityMode = Ext.Element.DISPLAY;
			controlSelectionEl.addClass('x-layout-control-select');
			Ext.designModeControlSelectionEl = controlSelectionEl;
		}
		if (control.el) {
			var position = control.getPosition();
			var width = control.getWidth();
			var height = control.getHeight();
			controlSelectionEl.setSize(width - 1, height - 1);
			controlSelectionEl.setLeftTop(position[0], position[1]);
			controlSelectionEl.show();
		}
		return controlSelectionEl;
	},

	setEnabled: function(enabled, enableChildren) {
		Ext.Container.superclass.setEnabled.call(this, enabled);
		if (!this.items) {
			return;
		}
		if (enableChildren === true) {
			var items = this.items.items;
			for (var i = 0, itemLength = items.length; i < itemLength; i++) {
				items[i].setEnabled(enabled, enableChildren);
			}
		}
	},

	setDisabled: function(disabled, disableChildren) {
		Ext.Container.superclass.setDisabled.call(this, disabled);
		if (!this.items) {
			return;
		}
		if (disableChildren === true) {
			var items = this.items.items;
			for (var i = 0, itemLength = items.length; i < itemLength; i++) {
				items[i].setDisabled(disabled, disableChildren);
			}
		}
	},

	hideControlSelection: function(controlSelectionEl) {
		if (controlSelectionEl) {
			controlSelectionEl.hide();
		}
	}
});

Ext.Container.LAYOUTS = {};

Ext.reg('container', Ext.Container);

Ext.layout.ContainerLayout = function (config) {
	Ext.apply(this, config);
	this.init();
};

Ext.layout.ContainerLayout.prototype = {
	monitorResize: false,
	activeItem: null,

	layout: function () {
		var target = this.container.getLayoutTarget();
		this.onLayout(this.container, target);
		this.container.fireEvent('afterlayout', this.container, this);
	},

	onLayout: function (ct, target) {
		this.renderAll(ct, target);
	},

	init: Ext.emptyFn,

	isValidParent: function (c, target) {
		var el = c.getPositionEl ? c.getPositionEl() : c.getEl();
		return el.dom.parentNode == target.dom;
	},

	renderAll: function (ct, target) {
		var items = ct.items.items;
		for (var i = 0, len = items.length; i < len; i++) {
			var c = items[i];
			if (c && (!c.rendered || !this.isValidParent(c, target))) {
				this.renderItem(c, i, target);
			}
		}
	},

	renderItem: function (c, position, target) {
		if (c && !c.rendered) {
			c.render(target, position);
			if (this.extraCls) {
				var t = c.getPositionEl ? c.getPositionEl() : c;
				t.addClass(this.extraCls);
			}
			if (this.renderHidden && c != this.activeItem) {
				c.hide();
			}
		} else if (c && !this.isValidParent(c, target)) {
			if (this.extraCls) {
				c.addClass(this.extraCls);
			}
			if (typeof position == 'number') {
				position = target.dom.childNodes[position];
			}
			try {
				// TODO Mozila Chrome dom exception
				target.dom.insertBefore(c.getResizeEl().dom, position || null);
			} catch (e) { }
			if (this.renderHidden && c != this.activeItem) {
				c.hide();
			}
		}
	},

	onResize: function () {
		if (this.container.collapsed) {
			return;
		}
		var b = this.container.bufferResize;
		if (b) {
			if (!this.resizeTask) {
				this.resizeTask = new Ext.util.DelayedTask(this.layout, this);
				this.resizeBuffer = typeof b == 'number' ? b : 100;
			}
			this.resizeTask.delay(this.resizeBuffer);
		} else {
			this.layout();
		}
	},

	setContainer: function (ct) {
		if (this.monitorResize && ct != this.container) {
			if (this.container) {
				this.container.un('resize', this.onResize, this);
			}
			if (ct) {
				ct.on('resize', this.onResize, this);
			}
		}
		this.container = ct;
	},

	parseMargins: function (v) {
		var ms = v.split(' ');
		var len = ms.length;
		if (len == 1) {
			ms[1] = ms[0];
			ms[2] = ms[0];
			ms[3] = ms[0];
		}
		if (len == 2) {
			ms[2] = ms[0];
			ms[3] = ms[1];
		}
		return {
			top: parseInt(ms[0], 10) || 0,
			right: parseInt(ms[1], 10) || 0,
			bottom: parseInt(ms[2], 10) || 0,
			left: parseInt(ms[3], 10) || 0
		};
	},

	destroy: Ext.emptyFn
};

Ext.Container.LAYOUTS['auto'] = Ext.layout.ContainerLayout;

Ext.layout.TableLayout = Ext.extend(Ext.layout.ContainerLayout, {
	monitorResize: false,

	setContainer: function (ct) {
		Ext.layout.TableLayout.superclass.setContainer.call(this, ct);

		this.currentRow = 0;
		this.currentColumn = 0;
		this.cells = [];
	},

	onLayout: function (ct, target) {
		var cs = ct.items.items, len = cs.length, c, i;

		if (!this.table) {
			target.addClass('x-table-layout-ct');

			this.table = target.createChild(
                { tag: 'table', cls: 'x-table-layout', cellspacing: 0, cn: { tag: 'tbody'} }, null, true);

			this.renderAll(ct, target);
		}
	},

	getRow: function (index) {
		var row = this.table.tBodies[0].childNodes[index];
		if (!row) {
			row = document.createElement('tr');
			this.table.tBodies[0].appendChild(row);
		}
		return row;
	},

	getNextCell: function (c) {
		var cell = this.getNextNonSpan(this.currentColumn, this.currentRow);
		var curCol = this.currentColumn = cell[0], curRow = this.currentRow = cell[1];
		for (var rowIndex = curRow; rowIndex < curRow + (c.rowspan || 1); rowIndex++) {
			if (!this.cells[rowIndex]) {
				this.cells[rowIndex] = [];
			}
			for (var colIndex = curCol; colIndex < curCol + (c.colspan || 1); colIndex++) {
				this.cells[rowIndex][colIndex] = true;
			}
		}
		var td = document.createElement('td');
		if (c.cellId) {
			td.id = c.cellId;
		}
		var cls = 'x-table-layout-cell';
		if (c.cellCls) {
			cls += ' ' + c.cellCls;
		}
		td.className = cls;
		if (c.colspan) {
			td.colSpan = c.colspan;
		}
		if (c.rowspan) {
			td.rowSpan = c.rowspan;
		}
		this.getRow(curRow).appendChild(td);
		return td;
	},

	getNextNonSpan: function (colIndex, rowIndex) {
		var cols = this.columns;
		while ((cols && colIndex >= cols) || (this.cells[rowIndex] && this.cells[rowIndex][colIndex])) {
			if (cols && colIndex >= cols) {
				rowIndex++;
				colIndex = 0;
			} else {
				colIndex++;
			}
		}
		return [colIndex, rowIndex];
	},

	renderItem: function (c, position, target) {
		if (c && !c.rendered) {
			c.render(this.getNextCell(c));
		}
	},

	isValidParent: function (c, target) {
		return true;
	}
});

Ext.Container.LAYOUTS['table'] = Ext.layout.TableLayout;

Ext.WindowGroup = function () {
	var list = {};
	var accessList = [];
	var front = null;

	var sortWindows = function (d1, d2) {
		return (!d1._lastAccess || d1._lastAccess < d2._lastAccess) ? -1 : 1;
	};

	var orderWindows = function () {
		var a = accessList, len = a.length;
		if (len > 0) {
			a.sort(sortWindows);
			var seed = a[0].manager.zseed;
			for (var i = 0; i < len; i++) {
				var win = a[i];
				if (win && !win.hidden) {
					win.setZIndex(seed + (i * 10));
				}
			}
		}
		activateLast();
	};

	var setActiveWin = function (win) {
		if (win != front) {
			if (front) {
				front.setActive(false);
			}
			front = win;
			if (win) {
				win.setActive(true);
			}
		}
	};

	var activateLast = function () {
		for (var i = accessList.length - 1; i >= 0; --i) {
			if (!accessList[i].hidden) {
				setActiveWin(accessList[i]);
				return;
			}
		}
		setActiveWin(null);
	};

	return {
		zseed: 9000,

		register: function (win) {
			list[win.id] = win;
			accessList.push(win);
			win.on('hide', activateLast);
		},

		unregister: function (win) {
			delete list[win.id];
			win.un('hide', activateLast);
			accessList.remove(win);
		},

		get: function (id) {
			return typeof id == "object" ? id : list[id];
		},

		bringToFront: function (win) {
			win = this.get(win);
			if (win != front) {
				win._lastAccess = new Date().getTime();
				orderWindows();
				return true;
			}
			return false;
		},

		sendToBack: function (win) {
			win = this.get(win);
			win._lastAccess = -(new Date().getTime());
			orderWindows();
			return win;
		},

		hideAll: function () {
			for (var id in list) {
				if (list[id] && typeof list[id] != "function" && list[id].isVisible()) {
					list[id].hide();
				}
			}
		},

		getActive: function () {
			return front;
		},

		getBy: function (fn, scope) {
			var r = [];
			for (var i = accessList.length - 1; i >= 0; --i) {
				var win = accessList[i];
				if (fn.call(scope || win, win) !== false) {
					r.push(win);
				}
			}
			return r;
		},

		each: function (fn, scope) {
			for (var id in list) {
				if (list[id] && typeof list[id] != "function") {
					if (fn.call(scope || list[id], list[id]) === false) {
						return;
					}
				}
			}
		}
	};
};

Ext.WindowMgr = new Ext.WindowGroup();

Ext.dd.PanelProxy = function (panel, config) {
	this.isVisible = true,
	this.panel = panel;
	this.id = this.panel.id + '-ddproxy';
	Ext.apply(this, config);
};

Ext.dd.PanelProxy.prototype = {
	insertProxy: true,
	setStatus: Ext.emptyFn,
	reset: Ext.emptyFn,
	update: Ext.emptyFn,
	stop: Ext.emptyFn,
	sync: Ext.emptyFn,

	getEl: function () {
		return this.ghost;
	},

	getGhost: function () {
		return this.ghost;
	},

	getProxy: function () {
		return this.proxy;
	},

	hide: function () {
		if (this.ghost) {
			if (this.proxy) {
				this.proxy.remove();
				delete this.proxy;
			}
			this.panel.el.dom.style.display = '';
			this.ghost.remove();
			delete this.ghost;
		}
	},

	show: function () {
		if (!this.ghost) {
			this.ghost = this.panel.createGhost(undefined, undefined, Ext.getBody());
			this.ghost.setXY(this.panel.el.getXY())
			if (this.insertProxy) {
				this.proxy = this.panel.el.insertSibling({ cls: 'x-panel-dd-spacer' });
				this.proxy.setSize(this.panel.getSize());
			}
			this.panel.el.dom.style.display = 'none';
		}
	},

	repair: function (xy, callback, scope) {
		this.hide();
		if (typeof callback == "function") {
			callback.call(scope || this);
		}
	},

	moveProxy: function (parentNode, before) {
		if (this.proxy) {
			parentNode.insertBefore(this.proxy.dom, before);
		}
	}
};

Ext.state.Provider = function () {
	this.addEvents("statechange");
	this.state = {};
	Ext.state.Provider.superclass.constructor.call(this);
};

Ext.extend(Ext.state.Provider, Ext.util.Observable, {

	get: function (name, defaultValue) {
		return typeof this.state[name] == "undefined" ?
            defaultValue : this.state[name];
	},

	clear: function (name) {
		delete this.state[name];
		this.fireEvent("statechange", this, name, null);
	},

	set: function (name, value) {
		this.state[name] = value;
		this.fireEvent("statechange", this, name, value);
	},

	decodeValue: function (cookie) {
		var re = /^(a|n|d|b|s|o)\:(.*)$/;
		var matches = re.exec(unescape(cookie));
		if (!matches || !matches[1]) return;
		var type = matches[1];
		var v = matches[2];
		switch (type) {
			case "n":
				return parseFloat(v);
			case "d":
				return new Date(Date.parse(v));
			case "b":
				return (v == "1");
			case "a":
				var all = [];
				var values = v.split("^");
				for (var i = 0, len = values.length; i < len; i++) {
					all.push(this.decodeValue(values[i]));
				}
				return all;
			case "o":
				var all = {};
				var values = v.split("^");
				for (var i = 0, len = values.length; i < len; i++) {
					var kv = values[i].split("=");
					all[kv[0]] = this.decodeValue(kv[1]);
				}
				return all;
			default:
				return v;
		}
	},

	encodeValue: function (v) {
		var enc;
		if (typeof v == "number") {
			enc = "n:" + v;
		} else if (typeof v == "boolean") {
			enc = "b:" + (v ? "1" : "0");
		} else if (Ext.isDate(v)) {
			enc = "d:" + v.toGMTString();
		} else if (Ext.isArray(v)) {
			var flat = "";
			for (var i = 0, len = v.length; i < len; i++) {
				flat += this.encodeValue(v[i]);
				if (i != len - 1) flat += "^";
			}
			enc = "a:" + flat;
		} else if (typeof v == "object") {
			var flat = "";
			for (var key in v) {
				if (typeof v[key] != "function" && v[key] !== undefined) {
					flat += key + "=" + this.encodeValue(v[key]) + "^";
				}
			}
			enc = "o:" + flat.substring(0, flat.length - 1);
		} else {
			enc = "s:" + v;
		}
		return escape(enc);
	}
});

Ext.state.Manager = function () {
	var provider = new Ext.state.Provider();

	return {
		setProvider: function (stateProvider) {
			provider = stateProvider;
		},

		get: function (key, defaultValue) {
			return provider.get(key, defaultValue);
		},

		set: function (key, value) {
			provider.set(key, value);
		},

		clear: function (key) {
			provider.clear(key);
		},

		getProvider: function () {
			return provider;
		}
	};
} ();

Ext.state.CookieProvider = function (config) {
	Ext.state.CookieProvider.superclass.constructor.call(this);
	this.path = "/";
	this.expires = new Date(new Date().getTime() + (1000 * 60 * 60 * 24 * 7));
	this.domain = null;
	this.secure = false;
	Ext.apply(this, config);
	this.state = this.readCookies();
};

Ext.extend(Ext.state.CookieProvider, Ext.state.Provider, {

	set: function (name, value) {
		if (typeof value == "undefined" || value === null) {
			this.clear(name);
			return;
		}
		this.setCookie(name, value);
		Ext.state.CookieProvider.superclass.set.call(this, name, value);
	},

	clear: function (name) {
		this.clearCookie(name);
		Ext.state.CookieProvider.superclass.clear.call(this, name);
	},

	readCookies: function () {
		var cookies = {};
		var c = document.cookie + ";";
		var re = /\s?(.*?)=(.*?);/g;
		var matches;
		while ((matches = re.exec(c)) != null) {
			var name = matches[1];
			var value = matches[2];
			if (name && name.substring(0, 3) == "ys-") {
				cookies[name.substr(3)] = this.decodeValue(value);
			}
		}
		return cookies;
	},

	setCookie: function (name, value) {
		document.cookie = "ys-" + name + "=" + this.encodeValue(value) +
           ((this.expires == null) ? "" : ("; expires=" + this.expires.toGMTString())) +
           ((this.path == null) ? "" : ("; path=" + this.path)) +
           ((this.domain == null) ? "" : ("; domain=" + this.domain)) +
           ((this.secure == true) ? "; secure" : "");
	},

	clearCookie: function (name) {
		document.cookie = "ys-" + name + "=null; expires=Thu, 01-Jan-70 00:00:01 GMT" +
           ((this.path == null) ? "" : ("; path=" + this.path)) +
           ((this.domain == null) ? "" : ("; domain=" + this.domain)) +
           ((this.secure == true) ? "; secure" : "");
	}
});

Ext.DataView = Ext.extend(Ext.LayoutControl, {
	selectedClass: "x-view-selected",
	emptyText: "",
	deferEmptyText: true,
	trackOver: false,
	last: false,

	initComponent: function () {
		Ext.DataView.superclass.initComponent.call(this);
		if (typeof this.tpl == "string") {
			this.tpl = new Ext.XTemplate(this.tpl);
		}
		this.addEvents(
			"beforeclick",
			"click",
			"mouseenter",
			"mouseleave",
			"containerclick",
			"dblclick",
			"selectionchange",
			"beforeselect"
		);
		this.all = new Ext.CompositeElementLite();
		this.selected = new Ext.CompositeElementLite();
	},

	onRender: function () {
		if (!this.el) {
			this.el = document.createElement('div');
			this.el.id = this.id;
		}
		Ext.DataView.superclass.onRender.apply(this, arguments);
	},

	afterRender: function () {
		Ext.DataView.superclass.afterRender.call(this);

		this.el.on({
			"click": this.onClick,
			"dblclick": this.onDblClick,
			scope: this
		});

		if (this.overClass || this.trackOver) {
			this.el.on({
				"mouseover": this.onMouseOver,
				"mouseout": this.onMouseOut,
				scope: this
			});
		}

		if (this.store) {
			this.setStore(this.store, true);
		}
	},

	refresh: function () {
		this.clearSelections(false, true);
		this.el.update("");
		var records = this.store.getRange();
		if (records.length < 1) {
			if (!this.deferEmptyText || this.hasSkippedEmptyText) {
				this.el.update(this.emptyText);
			}
			this.hasSkippedEmptyText = true;
			this.all.clear();
			return;
		}
		this.tpl.overwrite(this.el, this.collectData(records, 0));
		this.all.fill(Ext.query(this.itemSelector, this.el.dom));
		this.updateIndexes(0);
	},

	prepareData: function (data) {
		return data;
	},

	collectData: function (records, startIndex) {
		var r = [];
		for (var i = 0, len = records.length; i < len; i++) {
			r[r.length] = this.prepareData(records[i].data, startIndex + i, records[i]);
		}
		return r;
	},

	bufferRender: function (records) {
		var div = document.createElement('div');
		this.tpl.overwrite(div, this.collectData(records));
		return Ext.query(this.itemSelector, div);
	},

	onUpdate: function (ds, record) {
		var index = this.store.indexOf(record);
		var sel = this.isSelected(index);
		var original = this.all.elements[index];
		var node = this.bufferRender([record], index)[0];

		this.all.replaceElement(index, node, true);
		if (sel) {
			this.selected.replaceElement(original, node);
			this.all.item(index).addClass(this.selectedClass);
		}
		this.updateIndexes(index, index);
	},

	onAdd: function (ds, records, index) {
		if (this.all.getCount() == 0) {
			this.refresh();
			return;
		}
		var nodes = this.bufferRender(records, index), n, a = this.all.elements;
		if (index < this.all.getCount()) {
			n = this.all.item(index).insertSibling(nodes, 'before', true);
			a.splice.apply(a, [index, 0].concat(nodes));
		} else {
			n = this.all.last().insertSibling(nodes, 'after', true);
			a.push.apply(a, nodes);
		}
		this.updateIndexes(index);
	},

	onRemove: function (ds, record, index) {
		this.deselect(index);
		this.all.removeElement(index, true);
		this.updateIndexes(index);
	},

	refreshNode: function (index) {
		this.onUpdate(this.store, this.store.getAt(index));
	},

	updateIndexes: function (startIndex, endIndex) {
		var ns = this.all.elements;
		startIndex = startIndex || 0;
		endIndex = endIndex || ((endIndex === 0) ? 0 : (ns.length - 1));
		for (var i = startIndex; i <= endIndex; i++) {
			ns[i].viewIndex = i;
		}
	},

	setStore: function (store, initial) {
		if (!initial && this.store) {
			this.store.un("beforeload", this.onBeforeLoad, this);
			this.store.un("datachanged", this.refresh, this);
			this.store.un("add", this.onAdd, this);
			this.store.un("remove", this.onRemove, this);
			this.store.un("update", this.onUpdate, this);
			this.store.un("clear", this.refresh, this);
		}
		if (store) {
			store = Ext.StoreMgr.lookup(store);
			store.on("beforeload", this.onBeforeLoad, this);
			store.on("datachanged", this.refresh, this);
			store.on("add", this.onAdd, this);
			store.on("remove", this.onRemove, this);
			store.on("update", this.onUpdate, this);
			store.on("clear", this.refresh, this);
		}
		this.store = store;
		if (store) {
			this.refresh();
		}
	},

	findItemFromChild: function (node) {
		return Ext.fly(node).findParent(this.itemSelector, this.el);
	},

	onClick: function (e) {
		var item = e.getTarget(this.itemSelector, this.el);
		if (item) {
			var index = this.indexOf(item);
			if (this.onItemClick(item, index, e) !== false) {
				this.fireEvent("click", this, index, item, e);
			}
		} else {
			if (this.fireEvent("containerclick", this, e) !== false) {
				this.clearSelections();
			}
		}
	},

	onDblClick: function (e) {
		var item = e.getTarget(this.itemSelector, this.el);
		if (item) {
			this.fireEvent("dblclick", this, this.indexOf(item), item, e);
		}
	},

	onMouseOver: function (e) {
		var item = e.getTarget(this.itemSelector, this.el);
		if (item && item !== this.lastItem) {
			this.lastItem = item;
			Ext.fly(item).addClass(this.overClass);
			this.fireEvent("mouseenter", this, this.indexOf(item), item, e);
		}
	},

	onMouseOut: function (e) {
		if (this.lastItem) {
			if (!e.within(this.lastItem, true)) {
				Ext.fly(this.lastItem).removeClass(this.overClass);
				this.fireEvent("mouseleave", this, this.indexOf(this.lastItem), this.lastItem, e);
				delete this.lastItem;
			}
		}
	},

	onItemClick: function (item, index, e) {
		if (this.fireEvent("beforeclick", this, index, item, e) === false) {
			return false;
		}
		if (this.multiSelect) {
			this.doMultiSelection(item, index, e);
			e.preventDefault();
		} else if (this.singleSelect) {
			this.doSingleSelection(item, index, e);
			e.preventDefault();
		}
		return true;
	},

	doSingleSelection: function (item, index, e) {
		if (e.ctrlKey && this.isSelected(index)) {
			this.deselect(index);
		} else {
			this.select(index, false);
		}
	},

	doMultiSelection: function (item, index, e) {
		if (e.shiftKey && this.last !== false) {
			var last = this.last;
			this.selectRange(last, index, e.ctrlKey);
			this.last = last;
		} else {
			if ((e.ctrlKey || this.simpleSelect) && this.isSelected(index)) {
				this.deselect(index);
			} else {
				this.select(index, e.ctrlKey || e.shiftKey || this.simpleSelect);
			}
		}
	},

	getSelectionCount: function () {
		return this.selected.getCount()
	},

	getSelectedNodes: function () {
		return this.selected.elements;
	},

	getSelectedIndexes: function () {
		var indexes = [], s = this.selected.elements;
		for (var i = 0, len = s.length; i < len; i++) {
			indexes.push(s[i].viewIndex);
		}
		return indexes;
	},

	getSelectedRecords: function () {
		var r = [], s = this.selected.elements;
		for (var i = 0, len = s.length; i < len; i++) {
			r[r.length] = this.store.getAt(s[i].viewIndex);
		}
		return r;
	},

	getRecords: function (nodes) {
		var r = [], s = nodes;
		for (var i = 0, len = s.length; i < len; i++) {
			r[r.length] = this.store.getAt(s[i].viewIndex);
		}
		return r;
	},

	getRecord: function (node) {
		return this.store.getAt(node.viewIndex);
	},

	clearSelections: function (suppressEvent, skipUpdate) {
		if ((this.multiSelect || this.singleSelect) && this.selected.getCount() > 0) {
			if (!skipUpdate) {
				this.selected.removeClass(this.selectedClass);
			}
			this.selected.clear();
			this.last = false;
			if (!suppressEvent) {
				this.fireEvent("selectionchange", this, this.selected.elements);
			}
		}
	},

	isSelected: function (node) {
		return this.selected.contains(this.getNode(node));
	},

	deselect: function (node) {
		if (this.isSelected(node)) {
			node = this.getNode(node);
			this.selected.removeElement(node);
			if (this.last == node.viewIndex) {
				this.last = false;
			}
			Ext.fly(node).removeClass(this.selectedClass);
			this.fireEvent("selectionchange", this, this.selected.elements);
		}
	},

	select: function (nodeInfo, keepExisting, suppressEvent) {
		if (Ext.isArray(nodeInfo)) {
			if (!keepExisting) {
				this.clearSelections(true);
			}
			for (var i = 0, len = nodeInfo.length; i < len; i++) {
				this.select(nodeInfo[i], true, true);
			}
			if (!suppressEvent) {
				this.fireEvent("selectionchange", this, this.selected.elements);
			}
		} else {
			var node = this.getNode(nodeInfo);
			if (!keepExisting) {
				this.clearSelections(true);
			}
			if (node && !this.isSelected(node)) {
				if (this.fireEvent("beforeselect", this, node, this.selected.elements) !== false) {
					Ext.fly(node).addClass(this.selectedClass);
					this.selected.add(node);
					this.last = node.viewIndex;
					if (!suppressEvent) {
						this.fireEvent("selectionchange", this, this.selected.elements);
					}
				}
			}
		}
	},

	selectRange: function (start, end, keepExisting) {
		if (!keepExisting) {
			this.clearSelections(true);
		}
		this.select(this.getNodes(start, end), true);
	},

	getNode: function (nodeInfo) {
		if (typeof nodeInfo == "string") {
			return document.getElementById(nodeInfo);
		} else if (typeof nodeInfo == "number") {
			return this.all.elements[nodeInfo];
		}
		return nodeInfo;
	},

	getNodes: function (start, end) {
		var ns = this.all.elements;
		start = start || 0;
		end = typeof end == "undefined" ? Math.max(ns.length - 1, 0) : end;
		var nodes = [], i;
		if (start <= end) {
			for (i = start; i <= end && ns[i]; i++) {
				nodes.push(ns[i]);
			}
		} else {
			for (i = start; i >= end && ns[i]; i--) {
				nodes.push(ns[i]);
			}
		}
		return nodes;
	},

	indexOf: function (node) {
		node = this.getNode(node);
		if (typeof node.viewIndex == "number") {
			return node.viewIndex;
		}
		return this.all.indexOf(node);
	},

	onBeforeLoad: function () {
		if (this.loadingText) {
			this.clearSelections(false, true);
			this.el.update('<div class="loading-indicator">' + this.loadingText + '</div>');
			this.all.clear();
		}
	},

	onDestroy: function () {
		Ext.DataView.superclass.onDestroy.call(this);
		this.setStore(null);
	}
});
Ext.DataView["getNodes"] = Ext.DataView.getNodes;

Ext.reg('dataview', Ext.DataView);

Ext.MessageBox = function () {
	var dlg, opt, mask, waitTimer;
	var bodyEl, msgEl, progressBar, pp, iconEl, spacerEl;
	var buttons, bwidth, imageCls = '';

	var handleButton = function (button) {
		if (dlg.isVisible()) {
			dlg.hide();
			Ext.callback(opt.fn, opt.scope || window, [button], 1);
		}
	};

	var handleHide = function () {
		if (opt && opt.cls) {
			dlg.el.removeClass(opt.cls);
		}
		progressBar.reset();
	};

	var handleEsc = function (d, k, e) {
		if (opt && opt.closable !== false) {
			dlg.hide();
		}
		if (e) {
			e.stopEvent();
		}
	};

	var getButtonText = function (buttonName) {
		var buttonText = Ext.MessageBox.buttonText;
		var cachedButtonCaption = buttonText[buttonName];
		if (!Ext.isEmpty(cachedButtonCaption)) {
			return cachedButtonCaption;
		}
		var buttonCaption = Ext.StringList('WC.Common').getValue('MessageBox.Buttons.' + buttonName + '.Caption');
		if (Ext.isEmpty(buttonCaption)) {
			buttonCaption = Ext.MessageBox.defaultButtonText[buttonName];
		}
		buttonText[buttonName] = buttonCaption;
		return buttonCaption;
	};

	var updateButtons = function (b) {
		var width = 0;
		if (!b) {
			buttons["ok"].hide();
			buttons["cancel"].hide();
			buttons["yes"].hide();
			buttons["no"].hide();
			return width;
		}
		//dlg.footer.dom.style.display = '';
		for (var k in buttons) {
			if (typeof buttons[k] != "function") {
				if (b[k]) {
					buttons[k].show();
					buttons[k].setCaption(typeof b[k] == "string" ? b[k] : getButtonText(k));
					width += buttons[k].el.button.getWidth() + 15;
				} else {
					buttons[k].hide();
				}
			}
		}
		return width;
	};

	return {

		getDialog: function (caption) {
			if (!dlg) {
				dlg = new Terrasoft.Window({
					autoCreate: true,
					caption: caption,
					resizable: false,
					constrain: true,
					constrainHeader: true,
					minimizable: false,
					maximizable: false,
					stateful: false,
					modal: true,
					shim: true,
					buttonAlign: "center",
					width: 400,
					height: 100,
					minHeight: 80,
					useDefaultLayout: false,
					plain: true,
					footer: true,
					closable: true,
					close: function () {
						if (opt && opt.buttons && opt.buttons.no && !opt.buttons.cancel) {
							handleButton("no");
						} else {
							handleButton("cancel");
						}
					}
				});
				buttons = {};
				buttons["ok"] = dlg.addButton(getButtonText("ok"), handleButton.createCallback("ok"));
				buttons["yes"] = dlg.addButton(getButtonText("yes"), handleButton.createCallback("yes"));
				buttons["no"] = dlg.addButton(getButtonText("no"), handleButton.createCallback("no"));
				buttons["cancel"] = dlg.addButton(getButtonText("cancel"), handleButton.createCallback("cancel"));
				buttons["ok"].hideMode = buttons["yes"].hideMode = buttons["no"].hideMode = buttons["cancel"].hideMode = 'display';
				dlg.render(document.body);
				dlg.getEl().addClass('ts-window-dlg');
				mask = dlg.mask;
				bodyEl = dlg.body.createChild({
					// html: '<div class="ext-mb-icon"></div><div class="ext-mb-content"><span class="ext-mb-text"></span><br /><div class="ext-mb-fix-cursor"><input type="text" class="ext-mb-input" /><textarea class="ext-mb-textarea"></textarea></div></div>'
					html: '<div class="ext-mb-icon"></div><div class="ext-mb-content"><span class="ext-mb-text"></span><br /><div class="ext-mb-fix-cursor"></div></div>'
				});
				iconEl = Ext.get(bodyEl.dom.firstChild);
				var contentEl = bodyEl.dom.childNodes[1];
				msgEl = Ext.get(contentEl.firstChild);
				progressBar = new Ext.ProgressBar({
					renderTo: bodyEl
				});
				bodyEl.createChild({ cls: 'x-clear' });
			}
			return dlg;
		},

		updateText: function (text) {
			if (!dlg.isVisible() && !opt.width) {
				dlg.setSize(this.maxWidth, 100);
			}
			msgEl.update(text || '&#160;');
			var iw = imageCls != '' ? (iconEl.getWidth() + iconEl.getMargins('lr')) : 0;
			var mw = msgEl.getWidth() + msgEl.getMargins('lr');
			var fw = dlg.getFrameWidth('lr');
			var bw = dlg.body.getFrameWidth('lr');
			if (Ext.isIE && iw > 0) {
				iw += 3;
			}
			var w = Math.max(Math.min(opt.width || iw + mw + fw + bw, this.maxWidth),
				Math.max(opt.minWidth || this.minWidth, bwidth || 0));

			if (opt.prompt === true) {
				activeTextEl.setWidth(w - iw - fw - bw);
			}
			if (opt.progress === true || opt.wait === true) {
				progressBar.setSize(w - iw - fw - bw);
			}
			dlg.setSize(w, 'auto').center();
			return this;
		},

		updateProgress: function (value, progressText, msg) {
			progressBar.updateProgress(value, progressText);
			if (msg) {
				this.updateText(msg);
			}
			return this;
		},

		isVisible: function () {
			return dlg && dlg.isVisible();
		},

		hide: function () {
			if (this.isVisible()) {
				dlg.hide();
				handleHide();
			}
			return this;
		},

		show: function (options) {
			if (this.isVisible()) {
				this.hide();
			}
			opt = options;
			var d = this.getDialog(opt.caption || "&#160;");

			d.setCaption(opt.caption || "&#160;");
			var allowClose = (opt.closable !== false && opt.progress !== true && opt.wait !== true);
			d.tools.close.setDisplayed(allowClose);
			var bs = opt.buttons;
			var db = null;
			if (bs && bs.ok) {
				db = buttons["ok"];
			} else if (bs && bs.yes) {
				db = buttons["yes"];
			}
			if (db) {
				d.focusEl = db;
			}
			if (opt.imageCls) {
				d.setImageClass(opt.imageCls);
			}
			this.setMessageBoxType(d, opt.icon);
			this.setIcon(opt.icon);
			bwidth = updateButtons(opt.buttons);
			progressBar.setVisible(opt.progress === true || opt.wait === true);
			this.updateProgress(0, opt.progressText);
			this.updateText(opt.msg);
			if (opt.cls) {
				d.el.addClass(opt.cls);
			}
			d.proxyDrag = opt.proxyDrag === true;
			d.modal = opt.modal !== false;
			d.mask = opt.modal !== false ? mask : false;
			if (!d.isVisible()) {
				document.body.appendChild(dlg.el.dom);
				d.show(opt.animEl);
			}

			d.on('show', function () {
				if (allowClose === true) {
					d.keyMap.enable();
				} else {
					d.keyMap.disable();
				}
			}, this, { single: true });

			if (opt.wait === true) {
				progressBar.wait(opt.waitConfig);
			}
			return this;
		},

		setIcon: function (icon) {
			if (icon && icon != '') {
				iconEl.removeClass('x-hidden');
				iconEl.replaceClass(imageCls, icon);
				imageCls = icon;
			} else {
				iconEl.replaceClass(imageCls, 'x-hidden');
				imageCls = '';
			}
			return this;
		},

		setMessageBoxType: function (dlg, msgType) {
			var oldType = imageCls;
			if (msgType && msgType != '') {
				dlg.el.replaceClass(oldType, msgType);
			} else {
				dlg.el.replaceClass(oldType, "");
			}
			return this;
		},

		progress: function (caption, msg, progressText) {
			this.show({
				caption: caption,
				msg: msg,
				buttons: false,
				progress: true,
				closable: false,
				minWidth: this.minProgressWidth,
				progressText: progressText
			});
			return this;
		},

		wait: function (msg, caption, config) {
			this.show({
				caption: caption,
				msg: msg,
				buttons: false,
				closable: false,
				wait: true,
				modal: true,
				minWidth: this.minProgressWidth,
				waitConfig: config
			});
			return this;
		},

		alert: function (caption, msg, fn, scope) {
			this.show({
				caption: caption,
				msg: msg,
				buttons: this.OK,
				fn: fn,
				scope: scope
			});
			return this;
		},

		confirm: function (caption, msg, fn, scope) {
			this.show({
				caption: caption,
				msg: msg,
				buttons: this.YESNO,
				fn: fn,
				scope: scope,
				icon: this.QUESTION
			});
			return this;
		},

		ajaxEventConfirm: function (scope, caption, msg) {
			this.show({
				caption: caption,
				msg: msg,
				buttons: this.YESNO,
				fn: function (btn) { if (btn == 'yes') { this.before = null; Ext.AjaxEvent.request(this); } },
				scope: scope,
				icon: this.QUESTION
			});
			return false;
		},

		message: function (caption, msg, buttons, icon, fn, scope) {
			this.show({
				caption: caption,
				msg: msg,
				buttons: buttons,
				fn: fn,
				scope: scope,
				icon: icon
			});
			return this;
		},

		OK: { ok: true },
		CANCEL: { cancel: true },
		OKCANCEL: { ok: true, cancel: true },
		YESNO: { yes: true, no: true },
		YESNOCANCEL: { yes: true, no: true, cancel: true },
		INFO: 'ext-mb-info',
		WARNING: 'ext-mb-warning',
		QUESTION: 'ext-mb-question',
		ERROR: 'ext-mb-error',
		defaultTextHeight: 75,
		maxWidth: 600,
		minWidth: 100,
		minProgressWidth: 250,

		defaultButtonText: {
			ok: "OK",
			cancel: "Отмена",
			yes: "Да",
			no: "Нет"
		},

		buttonText: {}
	};
} ();

Ext.Msg = Ext.MessageBox;

Ext.Resizable = function (el, config) {
	this.el = Ext.get(el);

	if (config && config.wrap) {
		config.resizeChild = this.el;
		this.el = this.el.wrap(typeof config.wrap == "object" ? config.wrap : { cls: "xresizable-wrap" });
		this.el.id = this.el.dom.id = config.resizeChild.id + "-rzwrap";
		this.el.setStyle("overflow", "hidden");
		this.el.setPositioning(config.resizeChild.getPositioning());
		config.resizeChild.clearPositioning();
		if (!config.width || !config.height) {
			var csize = config.resizeChild.getSize();
			this.el.setSize(csize.width, csize.height);
		}
		if (config.pinned && !config.adjustments) {
			config.adjustments = "auto";
		}
	}

	this.proxy = this.el.createProxy({ tag: "div", cls: "x-resizable-proxy", id: this.el.id + "-rzproxy" }, Ext.getBody());
	this.proxy.unselectable();
	this.proxy.enableDisplayMode('block');

	Ext.apply(this, config);

	if (this.pinned) {
		this.disableTrackOver = true;
		this.el.addClass("x-resizable-pinned");
	}

	var position = this.el.getStyle("position");
	if (position != "absolute" && position != "fixed") {
		this.el.setStyle("position", "relative");
	}
	if (!this.handles) {
		this.handles = 's,e,se';
		if (this.multiDirectional) {
			this.handles += ',n,w';
		}
	}
	if (this.handles == "all") {
		this.handles = "n s e w ne nw se sw";
	}
	var hs = this.handles.split(/\s*?[,;]\s*?| /);
	var ps = Ext.Resizable.positions;
	for (var i = 0, len = hs.length; i < len; i++) {
		if (hs[i] && ps[hs[i]]) {
			var pos = ps[hs[i]];
			this[pos] = new Ext.Resizable.Handle(this, pos, this.disableTrackOver, this.transparent);
		}
	}

	this.corner = this.southeast;

	if (this.handles.indexOf("n") != -1 || this.handles.indexOf("w") != -1) {
		this.updateBox = true;
	}

	this.activeHandle = null;

	if (this.resizeChild) {
		if (typeof this.resizeChild == "boolean") {
			this.resizeChild = Ext.get(this.el.dom.firstChild, true);
		} else {
			this.resizeChild = Ext.get(this.resizeChild, true);
		}
	}

	if (this.adjustments == "auto") {
		var rc = this.resizeChild;
		var hw = this.west, he = this.east, hn = this.north, hs = this.south;
		if (rc && (hw || hn)) {
			rc.position("relative");
			rc.setLeft(hw ? hw.el.getWidth() : 0);
			rc.setTop(hn ? hn.el.getHeight() : 0);
		}
		this.adjustments = [
            (he ? -he.el.getWidth() : 0) + (hw ? -hw.el.getWidth() : 0),
            (hn ? -hn.el.getHeight() : 0) + (hs ? -hs.el.getHeight() : 0) - 1
        ];
	}

	if (this.draggable) {
		this.dd = this.dynamic ?
            this.el.initDD(null) : this.el.initDDProxy(null, { dragElId: this.proxy.id });
		this.dd.setHandleElId(this.resizeChild ? this.resizeChild.id : this.el.id);
	}

	this.addEvents(
        "beforeresize",
        "resize"
    );

	if (this.width !== null && this.height !== null) {
		this.resizeTo(this.width, this.height);
	} else {
		this.updateChildSize();
	}
	if (Ext.isIE) {
		this.el.dom.style.zoom = 1;
	}
	Ext.Resizable.superclass.constructor.call(this);
};

Ext.extend(Ext.Resizable, Ext.util.Observable, {
	resizeChild: false,
	adjustments: [0, 0],
	minWidth: 5,
	minHeight: 5,
	maxWidth: 10000,
	maxHeight: 10000,
	enabled: true,
	animate: false,
	duration: .35,
	dynamic: false,
	handles: false,
	multiDirectional: false,
	disableTrackOver: false,
	easing: 'easeOutStrong',
	widthIncrement: 0,
	heightIncrement: 0,
	pinned: false,
	width: null,
	height: null,
	preserveRatio: false,
	transparent: false,
	minX: 0,
	minY: 0,
	draggable: false,

	resizeTo: function (width, height) {
		this.el.setSize(width, height);
		this.updateChildSize();
		this.fireEvent("resize", this, width, height, null);
	},

	startSizing: function (e, handle) {
		this.fireEvent("beforeresize", this, e);
		if (this.enabled) {

			if (!this.overlay) {
				this.overlay = this.el.createProxy({ tag: "div", cls: "x-resizable-overlay", html: "&#160;" }, Ext.getBody());
				this.overlay.unselectable();
				this.overlay.enableDisplayMode("block");
				this.overlay.on("mousemove", this.onMouseMove, this);
				this.overlay.on("mouseup", this.onMouseUp, this);
			}
			this.overlay.setStyle("cursor", handle.el.getStyle("cursor"));

			this.resizing = true;
			this.startBox = this.el.getBox();
			this.startPoint = e.getXY();
			this.offsets = [(this.startBox.x + this.startBox.width) - this.startPoint[0],
                            (this.startBox.y + this.startBox.height) - this.startPoint[1]];

			this.overlay.setSize(Ext.lib.Dom.getViewWidth(true), Ext.lib.Dom.getViewHeight(true));
			this.overlay.show();

			if (this.constrainTo) {
				var ct = Ext.get(this.constrainTo);
				this.resizeRegion = ct.getRegion().adjust(
                    ct.getFrameWidth('t'),
                    ct.getFrameWidth('l'),
                    -ct.getFrameWidth('b'),
                    -ct.getFrameWidth('r')
                );
			}

			this.proxy.setStyle('visibility', 'hidden');
			this.proxy.show();
			this.proxy.setBox(this.startBox);
			if (!this.dynamic) {
				this.proxy.setStyle('visibility', 'visible');
			}
		}
	},

	onMouseDown: function (handle, e) {
		if (this.enabled) {
			e.stopEvent();
			this.activeHandle = handle;
			this.startSizing(e, handle);
		}
	},

	onMouseUp: function (e) {
		var size = this.resizeElement();
		this.resizing = false;
		this.handleOut();
		this.overlay.hide();
		this.proxy.hide();
		this.fireEvent("resize", this, size.width, size.height, e);
	},

	updateChildSize: function () {
		if (this.resizeChild) {
			var el = this.el;
			var child = this.resizeChild;
			var adj = this.adjustments;
			if (el.dom.offsetWidth) {
				var b = el.getSize(true);
				child.setSize(b.width + adj[0], b.height + adj[1]);
			}

			if (Ext.isIE) {
				setTimeout(function () {
					if (el.dom.offsetWidth) {
						var b = el.getSize(true);
						child.setSize(b.width + adj[0], b.height + adj[1]);
					}
				}, 10);
			}
		}
	},

	snap: function (value, inc, min) {
		if (!inc || !value) return value;
		var newValue = value;
		var m = value % inc;
		if (m > 0) {
			if (m > (inc / 2)) {
				newValue = value + (inc - m);
			} else {
				newValue = value - m;
			}
		}
		return Math.max(min, newValue);
	},

	resizeElement: function () {
		var box = this.proxy.getBox();
		if (this.updateBox) {
			this.el.setBox(box, false, this.animate, this.duration, null, this.easing);
		} else {
			this.el.setSize(box.width, box.height, this.animate, this.duration, null, this.easing);
		}
		this.updateChildSize();
		if (!this.dynamic) {
			this.proxy.hide();
		}
		return box;
	},

	constrain: function (v, diff, m, mx) {
		if (v - diff < m) {
			diff = v - m;
		} else if (v - diff > mx) {
			diff = mx - v;
		}
		return diff;
	},

	onMouseMove: function (e) {
		if (this.enabled) {
			try {
				if (this.resizeRegion && !this.resizeRegion.contains(e.getPoint())) {
					return;
				}
				var curSize = this.curSize || this.startBox;
				var x = this.startBox.x, y = this.startBox.y;
				var ox = x, oy = y;
				var w = curSize.width, h = curSize.height;
				var ow = w, oh = h;
				var mw = this.minWidth, mh = this.minHeight;
				var mxw = this.maxWidth, mxh = this.maxHeight;
				var wi = this.widthIncrement;
				var hi = this.heightIncrement;

				var eventXY = e.getXY();
				var diffX = -(this.startPoint[0] - Math.max(this.minX, eventXY[0]));
				var diffY = -(this.startPoint[1] - Math.max(this.minY, eventXY[1]));

				var pos = this.activeHandle.position;

				switch (pos) {
					case "east":
						w += diffX;
						w = Math.min(Math.max(mw, w), mxw);
						break;
					case "south":
						h += diffY;
						h = Math.min(Math.max(mh, h), mxh);
						break;
					case "southeast":
						w += diffX;
						h += diffY;
						w = Math.min(Math.max(mw, w), mxw);
						h = Math.min(Math.max(mh, h), mxh);
						break;
					case "north":
						diffY = this.constrain(h, diffY, mh, mxh);
						y += diffY;
						h -= diffY;
						break;
					case "west":
						diffX = this.constrain(w, diffX, mw, mxw);
						x += diffX;
						w -= diffX;
						break;
					case "northeast":
						w += diffX;
						w = Math.min(Math.max(mw, w), mxw);
						diffY = this.constrain(h, diffY, mh, mxh);
						y += diffY;
						h -= diffY;
						break;
					case "northwest":
						diffX = this.constrain(w, diffX, mw, mxw);
						diffY = this.constrain(h, diffY, mh, mxh);
						y += diffY;
						h -= diffY;
						x += diffX;
						w -= diffX;
						break;
					case "southwest":
						diffX = this.constrain(w, diffX, mw, mxw);
						h += diffY;
						h = Math.min(Math.max(mh, h), mxh);
						x += diffX;
						w -= diffX;
						break;
				}

				var sw = this.snap(w, wi, mw);
				var sh = this.snap(h, hi, mh);
				if (sw != w || sh != h) {
					switch (pos) {
						case "northeast":
							y -= sh - h;
							break;
						case "north":
							y -= sh - h;
							break;
						case "southwest":
							x -= sw - w;
							break;
						case "west":
							x -= sw - w;
							break;
						case "northwest":
							x -= sw - w;
							y -= sh - h;
							break;
					}
					w = sw;
					h = sh;
				}

				if (this.preserveRatio) {
					switch (pos) {
						case "southeast":
						case "east":
							h = oh * (w / ow);
							h = Math.min(Math.max(mh, h), mxh);
							w = ow * (h / oh);
							break;
						case "south":
							w = ow * (h / oh);
							w = Math.min(Math.max(mw, w), mxw);
							h = oh * (w / ow);
							break;
						case "northeast":
							w = ow * (h / oh);
							w = Math.min(Math.max(mw, w), mxw);
							h = oh * (w / ow);
							break;
						case "north":
							var tw = w;
							w = ow * (h / oh);
							w = Math.min(Math.max(mw, w), mxw);
							h = oh * (w / ow);
							x += (tw - w) / 2;
							break;
						case "southwest":
							h = oh * (w / ow);
							h = Math.min(Math.max(mh, h), mxh);
							var tw = w;
							w = ow * (h / oh);
							x += tw - w;
							break;
						case "west":
							var th = h;
							h = oh * (w / ow);
							h = Math.min(Math.max(mh, h), mxh);
							y += (th - h) / 2;
							var tw = w;
							w = ow * (h / oh);
							x += tw - w;
							break;
						case "northwest":
							var tw = w;
							var th = h;
							h = oh * (w / ow);
							h = Math.min(Math.max(mh, h), mxh);
							w = ow * (h / oh);
							y += th - h;
							x += tw - w;
							break;
					}
				}
				this.proxy.setBounds(x, y, w, h);
				if (this.dynamic) {
					this.resizeElement();
				}
			} catch (e) { }
		}
	},

	handleOver: function () {
		if (this.enabled) {
			this.el.addClass("x-resizable-over");
		}
	},

	handleOut: function () {
		if (!this.resizing) {
			this.el.removeClass("x-resizable-over");
		}
	},

	getEl: function () {
		return this.el;
	},

	getResizeChild: function () {
		return this.resizeChild;
	},

	destroy: function (removeEl) {
		this.proxy.remove();
		if (this.overlay) {
			this.overlay.removeAllListeners();
			this.overlay.remove();
		}
		var ps = Ext.Resizable.positions;
		for (var k in ps) {
			if (typeof ps[k] != "function" && this[ps[k]]) {
				var h = this[ps[k]];
				h.el.removeAllListeners();
				h.el.remove();
			}
		}
		if (removeEl) {
			this.el.update("");
			this.el.remove();
		}
	},

	syncHandleHeight: function () {
		var h = this.el.getHeight(true);
		if (this.west) {
			this.west.el.setHeight(h);
		}
		if (this.east) {
			this.east.el.setHeight(h);
		}
	}
});

Ext.Resizable.positions = {
	n: "north", s: "south", e: "east", w: "west", se: "southeast", sw: "southwest", nw: "northwest", ne: "northeast"
};

Ext.Resizable.Handle = function (rz, pos, disableTrackOver, transparent) {
	if (!this.tpl) {

		var tpl = Ext.DomHelper.createTemplate({ tag: "div", cls: "x-resizable-handle x-resizable-handle-{0}" });
		tpl.compile();
		Ext.Resizable.Handle.prototype.tpl = tpl;
	}
	this.position = pos;
	this.rz = rz;
	this.el = this.tpl.append(rz.el.dom, [this.position], true);
	this.el.unselectable();
	if (transparent) {
		this.el.setOpacity(0);
	}
	this.el.on("mousedown", this.onMouseDown, this);
	if (!disableTrackOver) {
		this.el.on("mouseover", this.onMouseOver, this);
		this.el.on("mouseout", this.onMouseOut, this);
	}
};

Ext.Resizable.Handle.prototype = {
	afterResize: function (rz) {
	},

	onMouseDown: function (e) {
		this.rz.onMouseDown(this, e);
	},

	onMouseOver: function (e) {
		this.rz.handleOver(this, e);
	},

	onMouseOut: function (e) {
		this.rz.handleOut(this, e);
	}
};

Ext.Editor = function (field, config) {
	this.field = field;
	Ext.Editor.superclass.constructor.call(this, config);
};

Ext.extend(Ext.Editor, Ext.Component, {
	value: "",
	alignment: "c-c?",
	shadow: "frame",
	constrain: false,
	swallowKeys: true,
	completeOnEnter: false,
	cancelOnEsc: false,
	updateEl: false,

	initComponent: function () {
		Ext.Editor.superclass.initComponent.call(this);
		this.addEvents(
			"beforestartedit",
			"startedit",
			"beforecomplete",
			"complete",
			"canceledit",
			"specialkey"
		);
	},

	onRender: function (ct, position) {
		this.el = new Ext.Layer({
			shadow: this.shadow,
			cls: "x-editor",
			parentEl: ct,
			shim: this.shim,
			shadowOffset: 4,
			id: this.id,
			constrain: this.constrain
		});
		this.el.setStyle("overflow", Ext.isGecko ? "auto" : "hidden");
		if (this.field.msgTarget != 'title') {
			this.field.msgTarget = 'qtip';
		}
		this.field.inEditor = true;
		this.field.render(this.el);
		if (Ext.isGecko) {
			this.field.el.dom.setAttribute('autocomplete', 'off');
		}
		this.field.on("specialkey", this.onSpecialKey, this);
		if (this.swallowKeys) {
			this.field.el.swallowEvent(['keydown', 'keypress']);
		}
		this.field.show();
		this.field.on("blur", this.onBlur, this);
		if (this.field.grow) {
			this.field.on("autosize", this.el.sync, this.el, { delay: 1 });
		}
	},

	onSpecialKey: function (field, e) {
		var key = e.getKey();
		if (this.completeOnEnter && key == e.ENTER) {
			e.stopEvent();
			this.completeEdit();
		} else if (this.cancelOnEsc && key == e.ESC) {
			this.cancelEdit();
		} else {
			this.fireEvent('specialkey', field, e);
		}
		if (this.field.triggerBlur && (key == e.ENTER || key == e.ESC || key == e.TAB)) {
			this.field.triggerBlur();
		}
	},

	startEdit: function (el, value) {
		if (this.editing) {
			this.completeEdit();
		}
		this.boundEl = Ext.get(el);
		var v = value !== undefined ? value : this.boundEl.dom.innerHTML;
		if (!this.rendered) {
			this.render(this.parentEl || document.body);
		}
		if (this.fireEvent("beforestartedit", this, this.boundEl, v) === false) {
			return;
		}
		this.startValue = v;
		this.field.setValue(v);
		this.doAutoSize();
		if (this.calcXOffsets) {
			var xOffset = Math.floor(this.field.getWidth() / 2);
			this.offsets = [-xOffset, 0];
		}
		this.el.alignTo(this.boundEl, this.alignment, this.offsets);
		this.boundEl.hide();
		this.editing = true;
		this.show();
		this.field.startEditing();
	},

	doAutoSize: function () {
		if (this.autoSize) {
			var sz = this.boundEl.getSize();
			switch (this.autoSize) {
				case "width":
					this.setSize(sz.width, "");
					break;
				case "height":
					this.setSize("", sz.height);
					break;
				default:
					this.setSize(sz.width, sz.height);
			}
		}
	},

	setSize: function (w, h) {
		delete this.field.lastSize;
		this.field.setSize(w, h);
		if (this.el) {
			if (Ext.isGecko2 || Ext.isOpera) {
				this.el.setSize(w, h);
			}
			this.el.sync();
		}
	},

	realign: function () {
		this.el.alignTo(this.boundEl, this.alignment);
	},

	completeEdit: function (remainVisible) {
		if (!this.editing) {
			return;
		}
		var v = this.getValue();
		if (this.revertInvalid !== false && !this.field.isValid()) {
			v = this.startValue;
			this.cancelEdit(true);
		}
		if (String(v) === String(this.startValue) && this.ignoreNoChange) {
			this.editing = false;
			this.hide();
			this.field.endEditing();
			return;
		}
		this.boundEl.show();
		if (this.fireEvent("beforecomplete", this, v, this.startValue) !== false) {
			this.editing = false;
			if (this.updateEl && this.boundEl) {
				this.boundEl.update(v);
			}
			if (remainVisible !== true) {
				this.hide();
			}
			this.fireEvent("complete", this, v, this.startValue);
			this.field.endEditing();
		}
	},

	onShow: function () {
		this.el.show();
		if (this.hideEl !== false) {
			this.boundEl.hide();
		}
		this.field.show();
		if (Ext.isIE && !this.fixIEFocus) {
			this.fixIEFocus = true;
			this.deferredFocus.defer(50, this);
		} else {
			this.field.focus();
		}
		this.fireEvent("startedit", this.boundEl, this.startValue);
	},

	deferredFocus: function () {
		if (this.editing && !this.handleFocus) {
			this.field.focus();
		}
	},

	cancelEdit: function (remainVisible) {
		if (this.editing) {
			var v = this.getValue();
			this.setValue(this.startValue);
			this.boundEl.show();
			if (remainVisible !== true) {
				this.hide();
			}
			this.fireEvent("canceledit", this, v, this.startValue);
		}
	},

	onBlur: function () {
		if (this.allowBlur !== true && this.editing) {
			this.completeEdit();
		}
	},

	onHide: function () {
		if (this.editing) {
			this.completeEdit();
			return;
		}
		this.field.blur();
		if (this.field.collapse) {
			this.field.collapse();
		}
		this.el.hide();
		if (this.hideEl !== false) {
			this.boundEl.show();
		}
	},

	setValue: function (v) {
		this.field.setValue(v);
	},

	getValue: function () {
		var field = this.field;
		return (field.getFormattedValue) ? field.getFormattedValue() : field.getValue();
	},

	beforeDestroy: function () {
		this.field.destroy();
		this.field = null;
	}
});

Ext.reg('editor', Ext.Editor);

Ext.form.Field = Ext.extend(Ext.LayoutControl, {
	invalidClass: "x-form-field-item-invalid",
	requiredClass: "x-form-item-label-required",
	focusClass: "x-form-focus",
	validationEvent: "keyup",
	validateOnBlur: true,
	validationDelay: 250,
	defaultAutoCreate: { tag: "input", type: "text", size: "20", autocomplete: "off" },
	fieldClass: "x-form-field",
	enabled: true,
	isFormField: true,
	valueInit: true,
	hasFocus: false,
	ignoreDataSourceProperties: false,

	initComponent: function () {
		Ext.form.Field.superclass.initComponent.call(this);
		this.addEvents(
			'focus',
			'blur',
			'specialkey',
			'change',
			'invalid',
			'valid'
		);
		var stringList = Ext.StringList('WC.Common');
		this.invalidText = stringList ? stringList.getValue('Field.InvalidValueMessage') : '';
		if (this.dataSource) {
			this.initDataEvents();
		}
	},

	initTool: function (toolBtn) {
		if (!toolBtn.events) {
			toolBtn = toolBtn || {};
			var toolBtnComp = Ext.ComponentMgr.create(Ext.apply(toolBtn, { ownerCt: this }), 'toolbutton');
			if (toolBtn.toolsWrap) {
				toolBtnComp.render(toolBtn.toolsWrap);
			}
			return toolBtnComp;
		}
		return toolBtn;
	},

	initTools: function (toolsConfig) {
		this.tools = [];
		toolsConfig = toolsConfig || [];
		Ext.each(toolsConfig, function (tool, i) {
			this.tools.push(this.initTool(tool));
			if (this.onInitTool) {
				this.onInitTool(this.tools[i]);
			}
		}, this);
	},

	getName: function () {
		return this.rendered && this.el.dom.name ? this.el.dom.name : (this.hiddenName || '');
	},
	
	setEnabled: function(enabled) {
		var column = this.getColumn();
		if (column && !this.dataSource.canEditColumn(column)) {
			enabled = false;
		}
		Ext.form.Field.superclass.setEnabled.call(this, enabled);
	},

	setDisabled: function(disabled) {
		this.setEnabled(!disabled);
	},

	onRender: function (ct, position) {
		Ext.form.Field.superclass.onRender.call(this, ct, position);
		if (!this.el) {
			var cfg = this.getAutoCreate();
			if (!cfg.name) {
				cfg.name = this.name || this.id;
			}
			if (this.inputType) {
				cfg.type = this.inputType;
			}
			this.el = ct.createChild(cfg, position);
		}
		var type = this.el.dom.type;
		if (type) {
			if (type == 'password') {
				type = 'text';
			}
			this.el.addClass('x-form-' + type);
		}
		if (this.readOnly) {
			this.el.dom.readOnly = true;
		}
		if (this.tabIndex !== undefined) {
			this.el.dom.setAttribute('tabIndex', this.tabIndex);
		}
		var labelEl = this.getLabelEl();
		if (labelEl) {
			if (this.required && this.enabled) {
				labelEl.addClass(this.requiredClass);
			}
		}
		this.el.addClass([this.fieldClass, this.cls]);
		var size = this.getFieldSize();
		if (size) {
			this.setMaxLength(size);
		}
	},

	setMaxLength: function (value) {
		this.maxLength = value;
		if (!this.rendered) {
			return;
		}
		if (value === undefined) {
			this.el.dom.removeAttribute('maxlength');
		} else {
			this.el.dom.setAttribute('maxlength', value);
		}
	},

	initValue: function () {
		try {
			this.valueInit = false;
			var column = this.getColumn();
			if (column) {
				var value = this.getColumnValue();
				this.setValue(value || "");
				return;
			}
			if (this.el.dom.value.length > 0 && this.el.dom.value != this.emptyText) {
				this.setValue(this.el.dom.value);
			} else {
				this.setValue(this.value);
			}
		} finally {
			this.originalValue = this.getValue();
			this.valueInit = true;
		}
	},

	isDirty: function () {
		if (!this.enabled) {
			return false;
		}
		return String(this.getValue()) !== String(this.originalValue);
	},

	afterRender: function () {
		Ext.form.Field.superclass.afterRender.call(this);
		if (this.required) {
			this.markRequired(this.required);
		}
		this.initEvents();
		if (this.designMode) {
			return;
		}
		this.initValue();
	},

	fireKey: function (e) {
		if (e.getKey() == e.ENTER) {
			this.checkChange();
		}
		if (e.isSpecialKey()) {
			this.fireEvent("specialkey", this, e);
		}
	},

	reset: function () {
		this.setValue(this.originalValue);
		this.clearInvalid();
	},

	setRequired: function (required) {
		this.markRequired(required);
		this.validate(true);
	},

	markRequired: function (required) {
		if (required == undefined) {
			return;
		}
		this.required = required;
		var labelEl = this.getLabelEl();
		if (!labelEl) {
			return;
		}
		if (required) {
			labelEl.addClass([this.requiredClass, 'x-display-name-required']);
			if (this.numberLabelEl) {
				this.numberLabelEl.addClass([this.requiredClass, 'x-display-name-required']);
			}
		} else {
			labelEl.removeClass([this.requiredClass, 'x-display-name-required']);
			if (this.numberLabelEl) {
				this.numberLabelEl.removeClass([this.requiredClass, 'x-display-name-required']);
			}
		}
		if (this.designMode) {
			this.validate(true);
		}
	},

	markInvalid: function (msg) {
		if (!this.rendered || !this.container) {
			return;
		}
		var el = this.wrap || this.getResizeEl();
		el.addClass(this.invalidClass);
		if (this.preventMark || this.required) {
			return;
		}
		msg = msg || this.invalidText;
		Ext.FormValidator.addMessage(Ext.Link.applyLinks(String.format(msg, this.id), this.getLinkConfig()));
		this.fireEvent('invalid', this, msg);
	},

	clearInvalid: function () {
		if (!this.rendered || !this.container) {
			return;
		}
		var el = this.wrap || this.getResizeEl();
		el.removeClass(this.invalidClass);
		if (this.preventMark) {
			return;
		}
		var vmp = Ext.FormValidator.validationMessagePanel;
		if (vmp = Ext.getCmp(vmp)) {
			vmp.remove(this.id + '_invalid');
		}
		this.fireEvent('valid', this);
	},

	getFieldSize: function () {
		var size = this.maxLength;
		if (!isNaN(size)) {
			return size;
		} else {
			var column = this.getColumn();
			if (column) {
				size = column.dataValueType.size;
			}
		}
		return size;
	},

	checkSize: function (value) {
		if (!value) {
			return '';
		}
		var size = this.getFieldSize();
		if (size && value.length > size) {
			value = value.substring(0, size);
			var column = this.getColumn();
			if (column) {
				this.dataSource.setColumnValue(column.name, value);
			}
		}
		return value;
	},

	initDataEvents: function () {
		this.initDataChangeEvent();
		var dataSource = this.dataSource;
		dataSource.on('loaded', this.onDataSourceLoaded, this);
		dataSource.on('activerowchanged', this.onDataSourceActiveRowChanged, this);
		dataSource.on('datachanged', this.onDataSourceDataChanged, this);
		dataSource.on('rowloaded', this.onDataSourceRowLoaded, this);
		dataSource.on('activerowvalidated', this.onDataSourceActiveRowValidated, this);
		if (this.ignoreDataSourceProperties === false) {
			dataSource.on('structureloaded', this.onDataSourceStructureLoaded, this);
			dataSource.on('onstructureloadedcomplete', this.onStructureLoadedComplete, this);
		}
	},

	onDestroy: function () {
		var dataSource = this.dataSource;
		if (dataSource) {
			dataSource.un('loaded', this.onDataSourceLoaded, this);
			dataSource.un('activerowchanged', this.onDataSourceActiveRowChanged, this);
			dataSource.un('datachanged', this.onDataSourceDataChanged, this);
			dataSource.un('rowloaded', this.onDataSourceRowLoaded, this);
			dataSource.un('structureloaded', this.onDataSourceStructureLoaded, this);
			dataSource.un('onstructureloadedcomplete', this.onStructureLoadedComplete, this);
			dataSource.un('activerowvalidated', this.onDataSourceActiveRowValidated, this);
		}
		Ext.form.Field.superclass.onDestroy.call(this);
	},

	initDataChangeEvent: function () {
		this.on("change", this.onChange, this);
	},

	initEvents: function () {
		this.el.on(Ext.isIE || Ext.isSafari3 ? "keydown" : "keypress", this.fireKey, this);
		this.el.on("focus", this.onFocus, this);
		var o = this.inEditor && Ext.isWindows && Ext.isGecko ? { buffer: 10} : null;
		this.el.on("blur", this.onBlur, this, o);
		this.originalValue = this.getValue();
	},

	onFocus: function() {
		var isAccesDenied = false;
		var column = this.getColumn();
		if (column) {
			isAccesDenied = !this.dataSource.canReadColumn(column);
		}
		if (this.designMode || isAccesDenied) {
			return;
		}
		if (this.focusClass) {
			this.el.addClass(this.focusClass);
		}
		if (!this.hasFocus) {
			this.hasFocus = true;
			this.startValue = this.getValue();
			Terrasoft.FocusManager.setFocusedControl.defer(10, this, [this]);
			this.fireEvent("focus", this);
		}
	},

	beforeBlur: Ext.emptyFn,

	onBlur: function () {
		this.beforeBlur();
		if (this.focusClass) {
			this.el.removeClass(this.focusClass);
		}
		this.hasFocus = false;
		if (this.validationEvent !== false && this.validateOnBlur && this.validationEvent != "blur") {
			var validationResult = this.validate(true);
		}
		this.checkChange();
		this.fireEvent("blur", this);
	},

	checkChange: function () {
		var value = this.getValue();
		var oldValue = this.startValue;
		if (String(value) !== String(oldValue)) {
			this.fireEvent('change', this, value, oldValue);
			this.startValue = value;
		}
	},

	onChange: function (o, columnValue, oldColumnValue, opt) {
		if (!this.dataSource) {
			return;
		}
		if (!opt || !opt.isInitByEvent) {
			var column = this.getColumn();
			if (column) {
				this.dataSource.setColumnValue(column.name, columnValue);
			}
		}
	},

	onDataSourceLoaded: function (dataSource) {
		var column = this.getColumn();
		if (!column) {
			return;
		}
		var value = this.getColumnValue();
		this.setValue(value, true);
	},

	onDataSourceActiveRowChanged: function (dataSource, primaryColumnValue) {
		var column = this.getColumn();
		if (!column) {
			return;
		}
		var value = this.getColumnValue();
		this.setValue(value, true);
	},

	onDataSourceActiveRowValidated: function (columnName, isValid, extraMessage) {
		var column = this.getColumn();
		if (!column || columnName != column.name) {
			return;
		}
		isValid === false ? this.markInvalid() : this.clearInvalid();
		this.serverValidationResult = isValid;
		this.validationMessage = extraMessage;
	},

	onDataSourceDataChanged: function (row, columnName) {
		var column = this.getColumn();
		if (!column || !row || columnName != column.name) {
			return;
		}
		this.setValue(row.getColumnValue(columnName), true);
	},

	onDataSourceRowLoaded: function (dataSource, rowColumns) {
		var column = this.getColumn();
		if (!column) {
			return;
		}
		var value = this.getColumnValue();
		this.setValue(value, true);
	},

	onStructureLoadedComplete: function () {
		var ownerCt = this.ownerCt;
		if (!ownerCt) {
			return;
		}
		var alignGroupContainer = ownerCt.getAlignGroupContainer();
		var deferLayoutList = Terrasoft.deferLayoutList;
		if (deferLayoutList && deferLayoutList.indexOf(alignGroupContainer) != -1) {
			alignGroupContainer.beginContentUpdateCallCounter = 1;
			deferLayoutList.remove(alignGroupContainer);
			if (deferLayoutList.length == 0) {
				delete Terrasoft.deferLayoutList;
			}
			alignGroupContainer.updateControlsCaptionWidth();
			alignGroupContainer.endContentUpdate();
			return;
		}
	},

	onDataSourceStructureLoaded: function (dataSource) {
		var ownerCt = this.ownerCt;
		if (ownerCt) {
			var deferLayoutList = Terrasoft.deferLayoutList || (Terrasoft.deferLayoutList = []);
			var alignGroupContainer = ownerCt.getAlignGroupContainer();
			if (deferLayoutList.indexOf(alignGroupContainer) == -1) {
				alignGroupContainer.beginContentUpdate();
				deferLayoutList.push(alignGroupContainer);
			}
		}
		var column = this.getColumn();
		if (!column) {
			return;
		}
		this.setPropertiesByColumn(column);
	},

	setPropertiesByColumn: function(column) {
		if (!column) {
			return;
		}
		this.setEnabled(this.enabled);
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

	setColumnName: function (columnName) {
		this.columnName = columnName;
		if (!this.dataSource || this.getColumnUId(this.columnUId)) {
			return;
		}
		var column = this.dataSource.getColumnByName(columnName);
		this.setPropertiesByColumn(column);
	},

	setColumnUId: function (columnUId) {
		this.columnUId = columnUId;
		if (!this.dataSource) {
			return;
		}
		var column = this.dataSource.getColumnByUId(columnUId);
		this.setPropertiesByColumn(column);
	},

	setDataSource: function (dataSource) {
		dataSource = this.dataSource = (typeof dataSource === 'string') ? window[dataSource] : dataSource;
		var column = this.getColumn();
		if (!column) {
			return;
		}
		this.setPropertiesByColumn(column);
	},

	getColumnUId: function (columnUId) {
		return columnUId === "00000000-0000-0000-0000-000000000000" ? null : columnUId;
	},

	getColumn: function () {
		var dataSource = this.dataSource;
		var columnUId = this.getColumnUId(this.columnUId);
		var columnName = this.columnName;
		if (!dataSource || (!columnUId && !columnName)) {
			return null;
		}
		return columnUId ? dataSource.getColumnByUId(columnUId) : dataSource.getColumnByName(columnName);
	},

	getColumnValue: function () {
		var dataSource = this.dataSource;
		var columnUId = this.getColumnUId(this.columnUId);
		return columnUId ? dataSource.getColumnValueByColumnUId(columnUId) : dataSource.getColumnValue(this.columnName);
	},

	isValid: function () {
		return this.validate(true);
	},

	validate: function(preventMark) {
		if (this.hidden) {
			return true;
		}
		var column = this.getColumn();
		if (column && !this.dataSource.canEditColumn(column)) {
			return true;
		}
		var restore = this.preventMark;
		this.preventMark = preventMark === true;
		var v = this.validateValue(this.processValue(this.getRawValue()));
		v = this.serverValidationResult === false ? false : v;
		if (v) {
			this.clearInvalid();
		}
		this.preventMark = restore;
		return v;
	},

	processValue: function (value) {
		return value;
	},

	validateValue: function (value) {
		return true;
	},

	getRawValue: function () {
		var v = this.rendered ? this.el.getValue() : Ext.value(this.value, '');
		if (v === this.emptyText) {
			v = '';
		}
		return v;
	},

	getValue: function () {
		if (!this.rendered) {
			return this.value;
		}
		var v = this.el.getValue();
		if (v === this.emptyText || v === undefined) {
			v = '';
		}
		return v;
	},

	getDisplayValue: function () {
		return this.getValue();
	},

	setRawValue: function (v) {
		return this.el.dom.value = (v === null || v === undefined ? '' : v);
	},

	setValue: function (v) {
		this.value = v;
		if (this.rendered) {
			this.el.dom.value = (v === null || v === undefined ? '' : v);
		}
		this.validate(true);
	},

	setReadOnly: function (readOnly) {
		if (this.rendered) {
			this.el.dom.setAttribute('readOnly', readOnly);
			this.el.dom.readOnly = readOnly;
		} else {
			this.readOnly = readOnly;
		}
	},

	getReadOnly: function () {
		return this.rendered ? this.el.dom.readOnly : this.readOnly;
	},

	getLinkConfig: function () {
		var caption = this.caption;
		return { linkId: this.id, caption: caption };
	},

	getValidationMessage: function (message, id, value) {
		if (!message) {
			return this.validationMessage || this.invalidText;
		}
		return this.validationMessage = Ext.Link.applyLinks(String.format(message, '{' + id + '}', value), this.getLinkConfig());
	},

	unFocus: function () {
	},

	isColumnAccessDenied: function() {
		var column = this.getColumn();
		var value = this.getColumnValue();
		var dataSource = this.dataSource;
		if (dataSource) {
			var text = dataSource.getColumnDisplayValue(column.name);
			if (Ext.isEmpty(text) && !Ext.isEmpty(value) && !Ext.ux.GUID.isEmptyGUID(value)
				|| !dataSource.canReadColumn(column)) {
				return true;
			}
		}
		return false;
	},

	setEmptyText: function() {
		var isColumnAccessDenied = this.isColumnAccessDenied();
		if (isColumnAccessDenied) {
			if (this.isEmptyTextEventsListenersSet !== true) {
				this.setDefaultEmptyText();
				this.emptyText = this.defaultEmptyText;
				this.on("focus", this.preFocus, this);
				this.on('blur', this.postBlur, this);
				this.isEmptyTextEventsListenersSet = true;
			}
			this.applyEmptyText();
		} else {
			if (this.isEmptyTextEventsListenersSet === true) {
				this.emptyText = null;
				this.un("focus", this.preFocus, this);
				this.un('blur', this.postBlur, this);
				this.isEmptyTextEventsListenersSet = false;
			}
		}
	},

	setDefaultEmptyText: function() {
		if (!this.defaultEmptyText) {
			this.defaultEmptyText = "";
		}
	}

});

Ext.reg('field', Ext.form.Field);

Ext.form.TextField = Ext.extend(Ext.form.Field, {
	grow: false,
	growMin: 30,
	growMax: 800,
	vtype: null,
	maskRe: null,
	disableKeyFilter: false,
	required: false,
	minLength: 0,
	selectOnFocus: false,
	validator: null,
	regex: null,
	regexText: "",
	emptyText: null,
	emptyClass: 'x-form-empty-field',

	initComponent: function () {
		Ext.form.TextField.superclass.initComponent.call(this);
		this.addEvents(
			'autosize',
			'keypress'
		);
		var stringList = Ext.StringList('WC.Common');
		if (stringList) {
			this.minLengthText = stringList.getValue('TextField.MinLengthMessage');
			this.maxLengthText = stringList.getValue('TextField.MaxLengthMessage');
			this.blankText = stringList.getValue('TextField.BlankMessage');
		}
		var maskRe = this.maskRe;
		if (maskRe != null && typeof maskRe === "string") {
			this.maskRe = new RegExp(maskRe);
		}
		var regex = this.regex;
		if (regex != null && typeof regex === "string") {
			this.regex = new RegExp(regex);
		}
	},

	initEvents: function () {
		Ext.form.TextField.superclass.initEvents.call(this);
		if (this.validationEvent == 'keyup') {
			this.validationTask = new Ext.util.DelayedTask(this.validate, this, [true]);
			this.el.on('keyup', this.filterValidation, this);
		}
		else if (this.validationEvent !== false) {
			this.el.on(this.validationEvent, this.validate.createDelegate(this, [true]), this, { buffer: this.validationDelay });
		}
		if (this.selectOnFocus || this.emptyText) {
			this.on("focus", this.preFocus, this);
			this.el.on('mousedown', function () {
				if (!this.hasFocus) {
					this.el.on('mouseup', function (e) {
						e.preventDefault();
					}, this, { single: true });
				}
			}, this);
			if (this.emptyText) {
				this.on('blur', this.postBlur, this);
				this.applyEmptyText();
			}
		}
		if (this.maskRe || (this.vtype && this.disableKeyFilter !== true && (this.maskRe = Ext.form.VTypes[this.vtype + 'Mask']))) {
			this.el.on("keypress", this.filterKeys, this);
		}
		if (this.grow) {
			this.el.on("keyup", this.onKeyUpBuffered, this, { buffer: 50 });
			this.el.on("click", this.autoSize, this);
		}

		if (this.enableKeyEvent) {
			this.el.on("keypress", this.onKeyPress, this);
		}
	},

	onRender: function () {
		if (this.isSecureValue) {
			this.inputType = 'password';
		}
		Ext.form.TextField.superclass.onRender.apply(this, arguments);
	},

	setIsSecureValue: function (isSecureValue) {
		this.isSecureValue = isSecureValue;
		this.inputType = isSecureValue ? 'password' : 'text';
		if (!this.rendered) {
			return;
		}
		Ext.getDom(this.el).setAttribute('type', this.inputType);
	},

	processValue: function (value) {
		if (this.stripCharsRe) {
			var newValue = value.replace(this.stripCharsRe, '');
			if (newValue !== value) {
				this.setRawValue(newValue);
				return newValue;
			}
		}
		return value;
	},

	filterValidation: function (e) {
		if (!e.isNavKeyPress()) {
			this.validationTask.delay(this.validationDelay);
		}
	},

	onKeyUpBuffered: function (e) {
		if (!e.isNavKeyPress()) {
			this.autoSize();
		}
	},

	onKeyPress: function (e) {
		this.fireEvent('keypress', this, e);
	},

	reset: function () {
		Ext.form.TextField.superclass.reset.call(this);
		this.applyEmptyText();
	},

	applyEmptyText: function () {
		if (this.rendered && this.emptyText && this.getRawValue().length < 1 && this.hasFocus == false) {
			this.setRawValue(this.emptyText);
			this.el.addClass(this.emptyClass);
		}
	},

	preFocus: function () {
		if (this.emptyText) {
			if (this.el.dom.value == this.emptyText) {
				this.setRawValue('');
			}
			this.el.removeClass(this.emptyClass);
		}
		if (this.selectOnFocus) {
			this.el.dom.select();
		}
	},

	postBlur: function () {
		this.applyEmptyText();
	},

	filterKeys: function (e) {
		if (e.ctrlKey) {
			return;
		}
		var k = e.getKey();
		if (Ext.isGecko && (e.isNavKeyPress() || k == e.BACKSPACE || (k == e.DELETE && e.button == -1))) {
			return;
		}
		var c = e.getCharCode(), cc = String.fromCharCode(c);
		if (!Ext.isGecko && e.isSpecialKey() && !cc) {
			return;
		}
		if (!this.maskRe.test(cc)) {
			e.stopEvent();
		}
	},

	setValue: function (v) {
		if (this.emptyText && this.el && v !== undefined && v !== null && v !== '') {
			this.el.removeClass(this.emptyClass);
		}
		Ext.form.TextField.superclass.setValue.apply(this, arguments);
		this.applyEmptyText();
		this.autoSize();
	},

	startEditing: function () {
	},

	endEditing: function () {
	},

	validateValue: function (value) {
		if (value.length < 1 || value === this.emptyText) {
			if (!this.required) {
				return true;
			} else {
				this.markInvalid(this.blankText);
				return false;
			}
		}
		if (value.length < this.minLength) {
			this.markInvalid(this.getValidationMessage(this.minLengthText, this.id, this.minLength));
			return false;
		}
		if (value.length > this.maxLength) {
			this.markInvalid(this.getValidationMessage(this.maxLengthText, this.id, this.maxLength));
			return false;
		}
		if (this.vtype) {
			var vt = Ext.form.VTypes;
			if (!vt[this.vtype](value, this)) {
				this.markInvalid(this.vtypeText || vt[this.vtype + 'Text']);
				return false;
			}
		}
		if (typeof this.validator == "function") {
			var msg = this.validator(value);
			if (msg !== true) {
				this.markInvalid(msg);
				return false;
			}
		}
		if (this.regex && !this.regex.test(value)) {
			this.markInvalid(this.regexText);
			return false;
		}
		return true;
	},

	selectText: function (start, end) {
		var v = this.getRawValue();
		if (v.length > 0) {
			start = start === undefined ? 0 : start;
			end = end === undefined ? v.length : end;
			var d = this.el.dom;
			if (d.setSelectionRange) {
				d.setSelectionRange(start, end);
			} else if (d.createTextRange) {
				var range = d.createTextRange();
				range.moveStart("character", start);
				range.moveEnd("character", end - v.length);
				range.select();
			}
		}
	},

	autoSize: function () {
		if (!this.grow || !this.rendered) {
			return;
		}
		if (!this.metrics) {
			this.metrics = Ext.util.TextMetrics.createInstance(this.el);
		}
		var el = this.el;
		var v = el.dom.value;
		var d = document.createElement('div');
		d.appendChild(document.createTextNode(v));
		v = d.innerHTML;
		d = null;
		v += "&#160;";
		var w = Math.min(this.growMax, Math.max(this.metrics.getWidth(v) + 10, this.growMin));
		this.el.setWidth(w);
		this.fireEvent("autosize", this, w);
	}
});

Ext.reg('textfield', Ext.form.TextField);

Ext.form.Hidden = Ext.extend(Ext.form.Field, {
	inputType: 'hidden',

	onRender: function () {
		Ext.form.Hidden.superclass.onRender.apply(this, arguments);
	},

	initEvents: function () {
		this.originalValue = this.getValue();
	},

	setValue: function (v) {
		this.value = v;
		var temp = this.el.dom.value;
		if (this.rendered) {
			this.el.dom.value = (v === null || v === undefined ? "" : v);
			this.validate(true);
		}
		if (this.el.dom.value != temp) {
			this.fireEvent("change");
		}
	},

	setSize: Ext.emptyFn,
	setWidth: Ext.emptyFn,
	setHeight: Ext.emptyFn,
	setPosition: Ext.emptyFn,
	setPagePosition: Ext.emptyFn,
	markInvalid: Ext.emptyFn,
	clearInvalid: Ext.emptyFn
});

Ext.reg('hidden', Ext.form.Hidden);

Ext.form.BasicForm = function (el, config) {
	Ext.apply(this, config);

	this.items = new Ext.util.MixedCollection(false, function (o) {
		return o.id || (o.id = Ext.id());
	});
	this.addEvents(
		'beforeaction',
		'actionfailed',
		'actioncomplete'
	);

	if (el) {
		this.initEl(el);
	}
	Ext.form.BasicForm.superclass.constructor.call(this);
};

Ext.extend(Ext.form.BasicForm, Ext.util.Observable, {
	timeout: 30,
	activeAction: null,
	trackResetOnLoad: false,

	initEl: function (el) {
		this.el = Ext.get(el);
		this.id = this.el.id || Ext.id();
		if (!this.standardSubmit) {
			this.el.on('submit', this.onSubmit, this);
		}
		this.el.addClass('x-form');
	},

	getEl: function () {
		return this.el;
	},

	onSubmit: function (e) {
		e.stopEvent();
	},

	destroy: function () {
		this.items.each(function (f) {
			Ext.destroy(f);
		});
		if (this.el) {
			this.el.removeAllListeners();
			this.el.remove();
		}
		this.purgeListeners();
	},

	isValid: function () {
		var valid = true;
		this.items.each(function (f) {
			if (!f.validate()) {
				valid = false;
			}
		});
		return valid;
	},

	isDirty: function () {
		var dirty = false;
		this.items.each(function (f) {
			if (f.isDirty()) {
				dirty = true;
				return false;
			}
		});
		return dirty;
	},

	doAction: function (action, options) {
		if (typeof action == 'string') {
			action = new Ext.form.Action.ACTION_TYPES[action](this, options);
		}
		if (this.fireEvent('beforeaction', this, action) !== false) {
			this.beforeAction(action);
			action.run.defer(100, action);
		}
		return this;
	},

	submit: function (options) {
		if (this.standardSubmit) {
			var v = this.isValid();
			if (v) {
				this.el.dom.submit();
			}
			return v;
		}
		this.doAction('submit', options);
		return this;
	},

	load: function (options) {
		this.doAction('load', options);
		return this;
	},

	updateRecord: function (record) {
		record.beginEdit();
		var fs = record.fields;
		fs.each(function (f) {
			var field = this.findField(f.name);
			if (field) {
				record.set(f.name, field.getValue());
			}
		}, this);
		record.endEdit();
		return this;
	},

	loadRecord: function (record) {
		this.setValues(record.data);
		return this;
	},

	beforeAction: function (action) {
		var o = action.options;
		if (o.waitMsg) {
			if (this.waitMsgTarget === true) {
				this.el.mask(o.waitMsg, 'x-mask-loading');
			} else if (this.waitMsgTarget) {
				this.waitMsgTarget = Ext.get(this.waitMsgTarget);
				this.waitMsgTarget.mask(o.waitMsg, 'x-mask-loading');
			} else {
				Ext.MessageBox.wait(o.waitMsg, o.waitTitle || this.waitTitle || 'Пожайлуста подождите...');
			}
		}
	},

	afterAction: function (action, success) {
		this.activeAction = null;
		var o = action.options;
		if (o.waitMsg) {
			if (this.waitMsgTarget === true) {
				this.el.unmask();
			} else if (this.waitMsgTarget) {
				this.waitMsgTarget.unmask();
			} else {
				Ext.MessageBox.updateProgress(1);
				Ext.MessageBox.hide();
			}
		}
		if (success) {
			if (o.reset) {
				this.reset();
			}
			Ext.callback(o.success, o.scope, [this, action]);
			this.fireEvent('actioncomplete', this, action);
		} else {
			Ext.callback(o.failure, o.scope, [this, action]);
			this.fireEvent('actionfailed', this, action);
		}
	},

	findField: function (id) {
		var field = this.items.get(id);
		if (!field) {
			this.items.each(function (f) {
				if (f.isFormField && (f.dataIndex == id || f.id == id || f.getName() == id)) {
					field = f;
					return false;
				}
			});
		}
		return field || null;
	},

	markInvalid: function (errors) {
		if (Ext.isArray(errors)) {
			for (var i = 0, len = errors.length; i < len; i++) {
				var fieldError = errors[i];
				var f = this.findField(fieldError.id);
				if (f) {
					f.markInvalid(fieldError.msg);
				}
			}
		} else {
			var field, id;
			for (id in errors) {
				if (typeof errors[id] != 'function' && (field = this.findField(id))) {
					field.markInvalid(errors[id]);
				}
			}
		}
		return this;
	},

	setValues: function (values) {
		if (Ext.isArray(values)) {
			for (var i = 0, len = values.length; i < len; i++) {
				var v = values[i];
				var f = this.findField(v.id);
				if (f) {
					f.setValue(v.value);
					if (this.trackResetOnLoad) {
						f.originalValue = f.getValue();
					}
				}
			}
		} else {
			var field, id;
			for (id in values) {
				if (typeof values[id] != 'function' && (field = this.findField(id))) {
					field.setValue(values[id]);
					if (this.trackResetOnLoad) {
						field.originalValue = field.getValue();
					}
				}
			}
		}
		return this;
	},

	getValues: function (asString) {
		var fs = Ext.lib.Ajax.serializeForm(this.el.dom);
		if (asString === true) {
			return fs;
		}
		return Ext.urlDecode(fs);
	},

	clearInvalid: function () {
		this.items.each(function (f) {
			f.clearInvalid();
		});
		return this;
	},

	reset: function () {
		this.items.each(function (f) {
			f.reset();
		});
		return this;
	},

	add: function () {
		this.items.addAll(Array.prototype.slice.call(arguments, 0));
		return this;
	},

	remove: function (field) {
		this.items.remove(field);
		return this;
	},

	render: function () {
		this.items.each(function (f) {
			if (f.isFormField && !f.rendered && document.getElementById(f.id)) {
				f.applyToMarkup(f.id);
			}
		});
		return this;
	},

	applyToFields: function (o) {
		this.items.each(function (f) {
			Ext.apply(f, o);
		});
		return this;
	},

	applyIfToFields: function (o) {
		this.items.each(function (f) {
			Ext.applyIf(f, o);
		});
		return this;
	}
});

Ext.BasicForm = Ext.form.BasicForm;

Ext.FormValidator = function () {
	var requiredFields = [], requiredLinks = [], serverInvalidFields = [], serverInvalidLinks = [], messages = [],
		 vmpItemId = 'validation';

	function clearArrays() {
		requiredFields = []; requiredLinks = []; messages = []; serverInvalidFields = []; serverInvalidLinks = [];
	}

	function updateVMP() {
		clearVMP();
		if (!Ext.FormValidator.invalidFieldsExist) {
			return;
		}
		var message = '';
		var vmp = Ext.FormValidator.getVMP();
		if (!vmp) {
			delete Ext.FormValidator.invalidFieldsExist;
			return;
		}
		if (requiredFields.length > 0) {
			var reqFieldsMsg = Ext.StringList('WC.Common').getValue('FormValidator.RequiredFieldsMessage'),
				reqFieldMsg = Ext.StringList('WC.Common').getValue('FormValidator.RequiredFieldMessage');
			message = Ext.Link.applyLinks(String.format((requiredFields.length == 1 ? reqFieldMsg :
				reqFieldsMsg) + '<br />', requiredFields.join(", ")), requiredLinks);
		}
		if (serverInvalidFields.length > 0) {
			var invalFieldsMsg = Ext.StringList('WC.Common')
					.getValue('FormValidator.InvalidByServerValidationFieldsMessage'),
				invalFieldMsg = Ext.StringList('WC.Common')
					.getValue('FormValidator.InvalidByServerValidationFieldMessage');
			message += Ext.Link.applyLinks(String.format((serverInvalidFields.length == 1 ? invalFieldMsg :
				invalFieldsMsg) + '<br />', serverInvalidFields.join(", ")), serverInvalidLinks);
		}
		Ext.each(messages, function (m) {
			message += m + "<br />";
		});
		if (Ext.isEmpty(message)) {
			delete Ext.FormValidator.invalidFieldsExist;
			return;
		}
		vmp.addMessage(vmpItemId, Ext.StringList('WC.Common').getValue('FormValidator.Warning'), message, 'warning');
		delete Ext.FormValidator.invalidFieldsExist;
	}

	function clearVMP() {
		var vmp = Ext.FormValidator.getVMP();
		if (vmp) {
			vmp.clear();
		}
	}

	var customValidators = [];

	function validateCustomValidators() {
		var validationResult = true;
		for (var i = 0, customValidatorsLength = customValidators.length; i < customValidatorsLength; i++) {
			var customValidator = customValidators[i];
			var validationFunc = customValidator.validationFunc;
			var scope = customValidator.scope;
			if (validationFunc.call(scope) !== true) {
				validationResult = false;
				var validationMessage = customValidator.validationMessage;
				messages.push(validationMessage + '<br />');
			}
		}
		return validationResult;
	};

	return {

		addCustomValidator: function (customValidationFunction, validationMessage, scope) {
			customValidators.push({
				validationFunc: customValidationFunction,
				validationMessage: validationMessage,
				scope: scope || window
			});
		},

		getVMP: function () {
			return Ext.FormValidator.vmp = Ext.FormValidator.vmp || Ext.getCmp(Ext.FormValidator.validationMessagePanel);
		},

		getVMPItemId: function () {
			return vmpItemId;
		},

		addMessage: function (msg) {
			if (!Ext.FormValidator.getVMP()) {
				return;
			}
			messages.push(msg);
		},

		isValid: function () {
			return this.validate(true);
		},

		validate: function (preventMark) {
			var result = true;
			clearArrays();
			var vmp = Ext.FormValidator.getVMP();
			if (vmp && vmp.ownerCt && vmp.ownerCt.beginContentUpdate) {
				vmp.ownerCt.beginContentUpdate();
			}
			clearVMP();
			var isPreventMark = preventMark == undefined ? true : preventMark;
			Ext.ComponentMgr.all.each(function (f) {
				var showInVMP = f.validate && f.validate(isPreventMark) == false;
				if (showInVMP) {
					result = f.serverValidationResult === false ? result : false;
					var validationResult = !f.getValidationResult ? null : f.getValidationResult();
					if (validationResult && validationResult.type == 'custom') {
						messages.push(validationResult.message);
					} else {
						if (f.required && (preventMark !== true)) {
							requiredFields.push("{" + f.id + "}");
							requiredLinks.push(f.getLinkConfig());
						}
					}
					if (f.serverValidationResult === false) {
						if (Ext.isEmpty(f.validationMessage)) {
							serverInvalidFields.push("{" + f.id + "}");
							serverInvalidLinks.push(f.getLinkConfig());
						} else {
							messages.push(Ext.Link.applyLinks(String.format(f.validationMessage + '<br />',
								"{" + f.id + "}"), f.getLinkConfig()));
						}
					}
					if (!Ext.FormValidator.invalidFieldsExist) {
						Ext.FormValidator.invalidFieldsExist = true;
					}
				}
			});
			result = result && validateCustomValidators();
			if (!result) {
				Ext.FormValidator.invalidFieldsExist = true;
			}
			if (preventMark !== true) {
				updateVMP();
			}
			if (vmp && vmp.ownerCt && vmp.ownerCt.endContentUpdate) {
				vmp.ownerCt.endContentUpdate();
				vmp.ownerCt.onContentChanged();
			}
			clearArrays();
			return result;
		}
	};
} ();

Ext.form.Action = function (form, options) {
	this.form = form;
	this.options = options || {};
};

Ext.form.Action.CLIENT_INVALID = 'client';

Ext.form.Action.SERVER_INVALID = 'server';

Ext.form.Action.CONNECT_FAILURE = 'connect';

Ext.form.Action.LOAD_FAILURE = 'load';

Ext.form.Action.prototype = {
	type: 'default',

	run: function (options) {
	},

	success: function (response) {
	},

	handleResponse: function (response) {
	},

	failure: function (response) {
		this.response = response;
		this.failureType = Ext.form.Action.CONNECT_FAILURE;
		this.form.afterAction(this, false);
	},

	processResponse: function (response) {
		this.response = response;
		if (!response.responseText) {
			return true;
		}
		this.result = this.handleResponse(response);
		return this.result;
	},

	getUrl: function (appendParams) {
		var url = this.options.url || this.form.url || this.form.el.dom.action;
		if (appendParams) {
			var p = this.getParams();
			if (p) {
				url += (url.indexOf('?') != -1 ? '&' : '?') + p;
			}
		}
		return url;
	},

	getMethod: function () {
		return (this.options.method || this.form.method || this.form.el.dom.method || 'POST').toUpperCase();
	},

	getParams: function () {
		var bp = this.form.baseParams;
		var p = this.options.params;
		if (p) {
			if (typeof p == "object") {
				p = Ext.urlEncode(Ext.applyIf(p, bp));
			} else if (typeof p == 'string' && bp) {
				p += '&' + Ext.urlEncode(bp);
			}
		} else if (bp) {
			p = Ext.urlEncode(bp);
		}
		return p;
	},

	createCallback: function (opts) {
		var opts = opts || {};
		return {
			success: this.success,
			failure: this.failure,
			scope: this,
			timeout: (opts.timeout * 1000) || (this.form.timeout * 1000),
			upload: this.form.fileUpload ? this.success : undefined
		};
	}
};

Ext.form.Action.Submit = function (form, options) {
	Ext.form.Action.Submit.superclass.constructor.call(this, form, options);
};

Ext.extend(Ext.form.Action.Submit, Ext.form.Action, {
	type: 'submit',

	run: function () {
		var o = this.options;
		var method = this.getMethod();
		var isGet = method == 'GET';
		if (o.clientValidation === false || this.form.isValid()) {
			Ext.Ajax.request(Ext.apply(this.createCallback(o), {
				form: this.form.el.dom,
				url: this.getUrl(isGet),
				method: method,
				headers: o.headers,
				params: !isGet ? this.getParams() : null,
				isUpload: this.form.fileUpload
			}));
		} else if (o.clientValidation !== false) {
			this.failureType = Ext.form.Action.CLIENT_INVALID;
			this.form.afterAction(this, false);
		}
	},

	success: function (response) {
		var result = this.processResponse(response);
		if (result === true || result.success) {
			this.form.afterAction(this, true);
			return;
		}
		if (result.errors) {
			this.form.markInvalid(result.errors);
			this.failureType = Ext.form.Action.SERVER_INVALID;
		}
		this.form.afterAction(this, false);
	},

	handleResponse: function (response) {
		if (this.form.errorReader) {
			var rs = this.form.errorReader.read(response);
			var errors = [];
			if (rs.records) {
				for (var i = 0, len = rs.records.length; i < len; i++) {
					var r = rs.records[i];
					errors[i] = r.data;
				}
			}
			if (errors.length < 1) {
				errors = null;
			}
			return {
				success: rs.success,
				errors: errors
			};
		}
		return Ext.decode(response.responseText);
	}
});

Ext.form.Action.Load = function (form, options) {
	Ext.form.Action.Load.superclass.constructor.call(this, form, options);
	this.reader = this.form.reader;
};

Ext.extend(Ext.form.Action.Load, Ext.form.Action, {
	type: 'load',

	run: function () {
		Ext.Ajax.request(Ext.apply(
			this.createCallback(this.options), {
				method: this.getMethod(),
				url: this.getUrl(false),
				headers: this.options.headers,
				params: this.getParams()
			}
		));
	},

	success: function (response) {
		var result = this.processResponse(response);
		if (result === true || !result.success || !result.data) {
			this.failureType = Ext.form.Action.LOAD_FAILURE;
			this.form.afterAction(this, false);
			return;
		}
		this.form.clearInvalid();
		this.form.setValues(result.data);
		this.form.afterAction(this, true);
	},

	handleResponse: function (response) {
		if (this.form.reader) {
			var rs = this.form.reader.read(response);
			var data = rs.records && rs.records[0] ? rs.records[0].data : null;
			return {
				success: rs.success,
				data: data
			};
		}
		return Ext.decode(response.responseText);
	}
});

Ext.form.Action.ACTION_TYPES = {
	'load': Ext.form.Action.Load,
	'submit': Ext.form.Action.Submit
};

Ext.form.VTypes = function () {
	var alpha = /^[a-zA-Z_]+$/;
	var alphanum = /^[a-zA-Z0-9_]+$/;
	var email = /^([\w]+)(.[\w]+)*@([\w-]+\.){1,5}([A-Za-z]){2,4}$/;
	var url = /(((https?)|(ftp)):\/\/([\-\w]+\.)+\w{2,3}(\/[%\-\w]+(\.\w{2,})?)*(([\w\-\.\?\\\/+@&#;`~=%!]*)(\.\w{2,})?)*\/?)/i;

	return {
		'email': function (v) {
			return email.test(v);
		},
		'emailText': 'Поле должно быть e-mail адрес в фолмате "user@domain.com"',
		'emailMask': /[a-z0-9_\.\-@]/i,
		'url': function (v) {
			return url.test(v);
		},
		'urlText': 'Поле должно быть URL в формате "http:/' + '/www.domain.com"',
		'alpha': function (v) {
			return alpha.test(v);
		},
		'alphaText': 'Поле должно содержать только буквы и символ _',
		'alphaMask': /[a-z_]/i,
		'alphanum': function (v) {
			return alphanum.test(v);
		},
		'alphanumText': 'Поле должно содержать только буквы, числа и символ _',
		'alphanumMask': /[a-z0-9_]/i
	};
} ();

Ext.ProgressBar = Ext.extend(Ext.LayoutControl, {
	baseCls: 'x-progress',
	waitTimer: null,

	initComponent: function () {
		Ext.ProgressBar.superclass.initComponent.call(this);
		this.addEvents("update");
	},

	onRender: function (ct, position) {
		Ext.ProgressBar.superclass.onRender.call(this, ct, position);

		var tpl = new Ext.Template(
            '<div class="{cls}-wrap">',
                '<div class="{cls}-inner">',
                    '<div class="{cls}-bar">',
                        '<div class="{cls}-text">',
                            '<div>&#160;</div>',
                        '</div>',
                    '</div>',
                    '<div class="{cls}-text {cls}-text-back">',
                        '<div>&#160;</div>',
                    '</div>',
                '</div>',
            '</div>'
        );

		if (position) {
			this.el = tpl.insertBefore(position, { cls: this.baseCls }, true);
		} else {
			this.el = tpl.append(ct, { cls: this.baseCls }, true);
		}
		if (this.id) {
			this.el.dom.id = this.id;
		}
		var inner = this.el.dom.firstChild;
		this.progressBar = Ext.get(inner.firstChild);

		if (this.textEl) {

			this.textEl = Ext.get(this.textEl);
			delete this.textTopEl;
		} else {

			this.textTopEl = Ext.get(this.progressBar.dom.firstChild);
			var textBackEl = Ext.get(inner.childNodes[1]);
			this.textTopEl.setStyle("z-index", 99).addClass('x-hidden');
			this.textEl = new Ext.CompositeElement([this.textTopEl.dom.firstChild, textBackEl.dom.firstChild]);
			this.textEl.setWidth(inner.offsetWidth);
		}
		this.progressBar.setHeight(inner.offsetHeight);
	},

	afterRender: function () {
		Ext.ProgressBar.superclass.afterRender.call(this);
		if (this.value) {
			this.updateProgress(this.value, this.text);
		} else {
			this.updateText(this.text);
		}
	},

	updateProgress: function (value, text) {
		this.value = value || 0;
		if (text) {
			this.updateText(text);
		}
		if (this.rendered) {
			var w = Math.floor(value * this.el.dom.firstChild.offsetWidth);
			this.progressBar.setWidth(w);
			if (this.textTopEl) {

				this.textTopEl.removeClass('x-hidden').setWidth(w);
			}
		}
		this.fireEvent('update', this, value, text);
		return this;
	},

	wait: function (o) {
		if (!this.waitTimer) {
			var scope = this;
			o = o || {};
			this.updateText(o.text);
			this.waitTimer = Ext.TaskMgr.start({
				run: function (i) {
					var inc = o.increment || 10;
					this.updateProgress(((((i + inc) % inc) + 1) * (100 / inc)) * .01);
				},
				interval: o.interval || 1000,
				duration: o.duration,
				onStop: function () {
					if (o.fn) {
						o.fn.apply(o.scope || this);
					}
					this.reset();
				},
				scope: scope
			});
		}
		return this;
	},

	isWaiting: function () {
		return this.waitTimer != null;
	},

	updateText: function (text) {
		this.text = text || '&#160;';
		if (this.rendered) {
			this.textEl.update(this.text);
		}
		return this;
	},

	syncProgressBar: function () {
		if (this.value) {
			this.updateProgress(this.value, this.text);
		}
		return this;
	},

	setSize: function (w, h) {
		Ext.ProgressBar.superclass.setSize.call(this, w, h);
		if (this.textTopEl) {
			var inner = this.el.dom.firstChild;
			this.textEl.setSize(inner.offsetWidth, inner.offsetHeight);
		}
		this.syncProgressBar();
		return this;
	},

	reset: function (hide) {
		this.updateProgress(0);
		if (this.textTopEl) {
			this.textTopEl.addClass('x-hidden');
		}
		if (this.waitTimer) {
			this.waitTimer.onStop = null;
			Ext.TaskMgr.stop(this.waitTimer);
			this.waitTimer = null;
		}
		if (hide === true) {
			this.hide();
		}
		return this;
	}
});

Ext.reg('progress', Ext.ProgressBar);

Ext.Slider = Ext.extend(Ext.LayoutControl, {
	vertical: false,
	minValue: 0,
	maxValue: 100,
	keyIncrement: 1,
	increment: 0,
	clickRange: [5, 15],
	clickToChange: true,
	animate: true,
	dragging: false,

	initComponent: function () {
		if (this.value === undefined) {
			this.value = this.minValue;
		}
		Ext.Slider.superclass.initComponent.call(this);
		this.keyIncrement = Math.max(this.increment, this.keyIncrement);
		this.addEvents(
			'beforechange',
			'change',
			'changecomplete',
			'dragstart',
			'drag',
			'dragend'
		);

		if (this.vertical) {
			Ext.apply(this, Ext.Slider.Vertical);
		}
	},

	onRender: function () {
		this.autoEl = {
			cls: 'x-slider ' + (this.vertical ? 'x-slider-vert' : 'x-slider-horz'),
			cn: { cls: 'x-slider-end', cn: { cls: 'x-slider-inner', cn: [{ cls: 'x-slider-thumb' }, { tag: 'a', cls: 'x-slider-focus', href: "#", tabIndex: '-1', hidefocus: 'on'}]} }
		};
		Ext.Slider.superclass.onRender.apply(this, arguments);
		this.endEl = this.el.first();
		this.innerEl = this.endEl.first();
		this.thumb = this.innerEl.first();
		this.halfThumb = (this.vertical ? this.thumb.getHeight() : this.thumb.getWidth()) / 2;
		this.focusEl = this.thumb.next();
		this.initEvents();
	},

	initEvents: function () {
		this.thumb.addClassOnOver('x-slider-thumb-over');
		this.mon(this.el, 'mousedown', this.onMouseDown, this);
		this.mon(this.el, 'keydown', this.onKeyDown, this);
		this.focusEl.swallowEvent("click", true);

		this.tracker = new Ext.dd.DragTracker({
			onBeforeStart: this.onBeforeDragStart.createDelegate(this),
			onStart: this.onDragStart.createDelegate(this),
			onDrag: this.onDrag.createDelegate(this),
			onEnd: this.onDragEnd.createDelegate(this),
			tolerance: 3,
			autoStart: 300
		});
		this.tracker.initEl(this.thumb);
		this.on('beforedestroy', this.tracker.destroy, this.tracker);
	},

	onMouseDown: function (e) {
		if (this.disabled) { return; }
		if (this.clickToChange && e.target != this.thumb.dom) {
			var local = this.innerEl.translatePoints(e.getXY());
			this.onClickChange(local);
		}
		this.focus();
	},

	onClickChange: function (local) {
		if (local.top > this.clickRange[0] && local.top < this.clickRange[1]) {
			this.setValue(Math.round(this.reverseValue(local.left)), undefined, true);
		}
	},

	onKeyDown: function (e) {
		if (this.disabled) { e.preventDefault(); return; }
		var k = e.getKey();
		switch (k) {
			case e.UP:
			case e.RIGHT:
				e.stopEvent();
				if (e.ctrlKey) {
					this.setValue(this.maxValue, undefined, true);
				} else {
					this.setValue(this.value + this.keyIncrement, undefined, true);
				}
				break;
			case e.DOWN:
			case e.LEFT:
				e.stopEvent();
				if (e.ctrlKey) {
					this.setValue(this.minValue, undefined, true);
				} else {
					this.setValue(this.value - this.keyIncrement, undefined, true);
				}
				break;
			default:
				e.preventDefault();
		}
	},

	doSnap: function (value) {
		if (!this.increment || this.increment == 1 || !value) {
			return value;
		}
		var newValue = value, inc = this.increment;
		var m = value % inc;
		if (m > 0) {
			if (m > (inc / 2)) {
				newValue = value + (inc - m);
			} else {
				newValue = value - m;
			}
		}
		return newValue.constrain(this.minValue, this.maxValue);
	},

	afterRender: function () {
		Ext.Slider.superclass.afterRender.apply(this, arguments);
		if (this.value !== undefined) {
			var v = this.normalizeValue(this.value);
			if (v !== this.value) {
				delete this.value;
				this.setValue(v, false);
			} else {
				this.moveThumb(this.translateValue(v), false);
			}
		}
	},

	getRatio: function () {
		var w = this.innerEl.getWidth();
		var v = this.maxValue - this.minValue;
		return v == 0 ? w : (w / v);
	},

	normalizeValue: function (v) {
		if (typeof v != 'number') {
			v = parseInt(v);
		}
		v = Math.round(v);
		v = this.doSnap(v);
		v = v.constrain(this.minValue, this.maxValue);
		return v;
	},

	setValue: function (v, animate, changeComplete) {
		v = this.normalizeValue(v);
		if (v !== this.value && this.fireEvent('beforechange', this, v, this.value) !== false) {
			this.value = v;
			this.moveThumb(this.translateValue(v), animate !== false);
			this.fireEvent('change', this, v);
			if (changeComplete) {
				this.fireEvent('changecomplete', this, v);
			}
		}
	},

	translateValue: function (v) {
		var ratio = this.getRatio();
		return (v * ratio) - (this.minValue * ratio) - this.halfThumb;
	},

	reverseValue: function (pos) {
		var ratio = this.getRatio();
		return (pos + this.halfThumb + (this.minValue * ratio)) / ratio;
	},

	moveThumb: function (v, animate) {
		if (!animate || this.animate === false) {
			this.thumb.setLeft(v);
		} else {
			this.thumb.shift({ left: v, stopFx: true, duration: .35 });
		}
	},

	focus: function () {
		this.focusEl.focus(10);
	},

	onBeforeDragStart: function (e) {
		return !this.disabled;
	},

	onDragStart: function (e) {
		this.thumb.addClass('x-slider-thumb-drag');
		this.dragging = true;
		this.dragStartValue = this.value;
		this.fireEvent('dragstart', this, e);
	},

	onDrag: function (e) {
		var pos = this.innerEl.translatePoints(this.tracker.getXY());
		this.setValue(Math.round(this.reverseValue(pos.left)), false);
		this.fireEvent('drag', this, e);
	},

	onDragEnd: function (e) {
		this.thumb.removeClass('x-slider-thumb-drag');
		this.dragging = false;
		this.fireEvent('dragend', this, e);
		if (this.dragStartValue != this.value) {
			this.fireEvent('changecomplete', this, this.value);
		}
	},

	onResize: function (w, h) {
		this.innerEl.setWidth(w - (this.el.getPadding('l') + this.endEl.getPadding('r')));
		this.syncThumb();
	},

	syncThumb: function () {
		if (this.rendered) {
			this.moveThumb(this.translateValue(this.value));
		}
	},

	getValue: function () {
		return this.value;
	}
});

Ext.reg('slider', Ext.Slider);

Ext.Slider.Vertical = {
	onResize: function (w, h) {
		this.innerEl.setHeight(h - (this.el.getPadding('t') + this.endEl.getPadding('b')));
		this.syncThumb();
	},

	getRatio: function () {
		var h = this.innerEl.getHeight();
		var v = this.maxValue - this.minValue;
		return h / v;
	},

	moveThumb: function (v, animate) {
		if (!animate || this.animate === false) {
			this.thumb.setBottom(v);
		} else {
			this.thumb.shift({ bottom: v, stopFx: true, duration: .35 });
		}
	},

	onDrag: function (e) {
		var pos = this.innerEl.translatePoints(this.tracker.getXY());
		var bottom = this.innerEl.getHeight() - pos.top;
		this.setValue(Math.round(bottom / this.getRatio()), false);
		this.fireEvent('drag', this, e);
	},

	onClickChange: function (local) {
		if (local.left > this.clickRange[0] && local.left < this.clickRange[1]) {
			var bottom = this.innerEl.getHeight() - local.top;
			this.setValue(Math.round(bottom / this.getRatio()), undefined, true);
		}
	}
};

Ext.History = (function () {
	var iframe, hiddenField;
	var ready = false;
	var currentToken;

	function getHash() {
		var href = top.location.href, i = href.indexOf("#");
		return i >= 0 ? href.substr(i + 1) : null;
	}

	function doSave() {
		hiddenField.value = currentToken;
	}

	function handleStateChange(token) {
		currentToken = token;
		Ext.History.fireEvent('change', token);
	}

	function updateIFrame(token) {
		var html = ['<html><body><div id="state">', token, '</div></body></html>'].join('');
		try {
			var doc = iframe.contentWindow.document;
			doc.open();
			doc.write(html);
			doc.close();
			return true;
		} catch (e) {
			return false;
		}
	}

	function checkIFrame() {
		if (!iframe.contentWindow || !iframe.contentWindow.document) {
			setTimeout(checkIFrame, 10);
			return;
		}

		var doc = iframe.contentWindow.document;
		var elem = doc.getElementById("state");
		var token = elem ? elem.innerText : null;

		var hash = getHash();

		setInterval(function () {
			doc = iframe.contentWindow.document;
			elem = doc.getElementById("state");

			var newtoken = elem ? elem.innerText : null;

			var newHash = getHash();

			if (newtoken !== token) {
				token = newtoken;
				handleStateChange(token);
				top.location.hash = token;
				hash = token;
				doSave();
			} else if (newHash !== hash) {
				hash = newHash;
				updateIFrame(newHash);
			}
		}, 50);
		ready = true;
		Ext.History.fireEvent('ready', Ext.History);
	}

	function startUp() {
		currentToken = hiddenField.value;

		if (Ext.isIE) {
			checkIFrame();
		} else {
			var hash = getHash();
			setInterval(function () {
				var newHash = getHash();
				if (newHash !== hash) {
					hash = newHash;
					handleStateChange(hash);
					doSave();
				}
			}, 50);
			ready = true;
			Ext.History.fireEvent('ready', Ext.History);
		}
	}

	return {
		fieldId: 'x-history-field',
		iframeId: 'x-history-frame',

		events: {},

		init: function (onReady, scope) {
			if (ready) {
				Ext.callback(onReady, scope, [this]);
				return;
			}
			if (!Ext.isReady) {
				Ext.onReady(function () {
					Ext.History.init(onReady, scope);
				});
				return;
			}
			hiddenField = Ext.getDom(Ext.History.fieldId);
			if (Ext.isIE) {
				iframe = Ext.getDom(Ext.History.iframeId);
			}
			this.addEvents('ready', 'change');
			if (onReady) {
				this.on('ready', onReady, scope, { single: true });
			}
			startUp();
		},

		add: function (token, preventDup) {
			if (preventDup !== false) {
				if (this.getToken() == token) {
					return true;
				}
			}
			if (Ext.isIE) {
				return updateIFrame(token);
			} else {
				top.location.hash = token;
				return true;
			}
		},

		back: function () {
			history.go(-1);
		},

		forward: function () {
			history.go(1);
		},

		getToken: function () {
			return ready ? currentToken : getHash();
		}
	};
})();

Ext.apply(Ext.History, new Ext.util.Observable());

Ext.Shadow = function (config) {
	Ext.apply(this, config);
	this.offset = 2;
	var o = this.offset, a = { h: 0 };
	var rad = Math.floor(this.offset / 2);
	a.w = 0;
	a.l = a.t = o;
	a.t = o;
	if (Ext.isIE) {
		rad = 1;
		a.l += rad;
		a.w -= rad;
		a.h -= rad;
		a.t += 1;
	}
	this.adjusts = a;
};

Ext.Shadow.prototype = {
	offset: 4,

	show: function (target) {
		target = Ext.get(target);
		if (!this.el) {
			Ext.Shadow.markup = '<div class="shadow"><div class="shadowinner">';
			this.el = Ext.Shadow.Pool.pull();
			if (this.el.dom.nextSibling != target.dom) {
				this.el.insertBefore(target);
			}
		}
		this.el.setStyle("z-index", this.zIndex || parseInt(target.getStyle("z-index"), 10) - 1);
		this.realign(
			target.getLeft(true),
			target.getTop(true),
			target.getWidth(),
			target.getHeight()
		);
		this.el.dom.style.display = "block";
	},

	isVisible: function () {
		return this.el ? true : false;
	},

	hide: function () {
		if (this.el) {
			this.el.dom.style.display = "none";
			Ext.Shadow.Pool.push(this.el);
			delete this.el;
		}
	},

	setZIndex: function (z) {
		this.zIndex = z;
		if (this.el) {
			this.el.setStyle("z-index", z);
		}
	},

	realign: function (l, t, w, h) {
		if (!this.el) {
			return;
		}
		var a = this.adjusts, d = this.el.dom, s = d.style;
		var iea = 0;
		s.left = (l + a.l) + "px";
		s.top = (t + a.t) + "px";
		var sw = (w + a.w), sh = (h + a.h), sws = sw + "px", shs = sh + "px";
		if (s.width != sws || s.height != shs) {
			s.width = sws;
			s.height = shs;
		}
	}

};

Ext.Shadow.Pool = function () {
	var p = [];
	var markup = '<div class="x-simple-shadow">';
	return {
		pull: function () {
			var sh = p.shift();
			if (!sh) {
				sh = Ext.get(Ext.DomHelper.insertHtml("beforeBegin", document.body.firstChild, markup));
				sh.autoBoxAdjust = false;
			}
			return sh;
		},

		push: function (sh) {
			p.push(sh);
		}
	};
} ();

Ext.AjaxEvent = new Ext.data.Connection({
	autoAbort: false,

	serializeForm: function (form) {
		return Ext.lib.Ajax.serializeForm(form);
	},

	setValue: function (form, name, value) {
		var input = null;
		if (form[name]) {
			input = form[name];
		} else {
			input = document.createElement("input");
			input.setAttribute("name", name);
			input.setAttribute("type", "hidden");
		}
		input.setAttribute("value", value);
		var parentElement = input.parentElement ? input.parentElement : input.parentNode;
		if (Ext.isEmpty(parentElement)) {
			form.appendChild(input);
		}
	},

	delayedF: function (el, remove) {
		if (el) {
			el.unmask();
			if (remove === true) {
				el.remove();
			}
		}
	},

	updateVMP: function () {
		var vmp = Ext.FormValidator.getVMP();
		if (!vmp) {
			return false;
		}
		vmp.clear();
		var stringList = Ext.StringList('WC.MessagePanel');
		var message = '<br />' + stringList.getValue('Message.RequestFailureInfo') + '.<br />' +
				stringList.getValue('Message.Support') + '<br />';
		vmp.addMessage(undefined, stringList.getValue('Message.RequestFailure'), message, 'warning');
		vmp.on("linkclick", function () { }, this);
		return true;
	},

	showFailure: function (response, errorMsg, options) {
		var bodySize = Ext.getBody().getViewSize();
		var width = (bodySize.width < 700) ? bodySize.width - 50 : 500;
		if (Ext.isEmpty(errorMsg)) {
			errorMsg = response.responseText;
		}
		var stringList = Ext.StringList('WC.MessagePanel');
		var detailsHeight = 100;
		var memoEditDetailInfo = new Terrasoft.MemoEdit({
			width: '100%',
			hidden: true,
			enabled: false,
			height: detailsHeight
		});
		var buttonOk = new Terrasoft.Button({
			caption: stringList.getValue('Message.Close'),
			handler: function () {
				win.close();
			}
		});
		if (options) {
			var memoEditValue;
			memoEditValue = 'Action: ' + options.action || '';
			if (options.control && options.control.id) {
				memoEditValue = memoEditValue + '\r\nControlId: ' + options.control.id;
			}
			if (options.params && options.params.submitAjaxEventConfig) {
				memoEditValue = memoEditValue + '\r\nSubmitAjaxEventConfig: ' + options.params.submitAjaxEventConfig;
			}
		}
		var win = new Terrasoft.Window({
			minHeight: 0,
			cls: 'mp-window',
			modal: true,
			caption: stringList.getValue('Message.Warning'),
			width: width,
			resizable: false,
			listeners: {
				"maximize": {
					fn: function (el) {
						var v = Ext.getBody().getViewSize();
						el.setSize(v.width, v.height);
					},
					scope: this
				},
				"show": function () {
					var anchorEl = Ext.get('showRequestErrorDetailInfo');
					anchorEl.on('click', function () {
						if (memoEditDetailInfo.hidden) {
							memoEditDetailInfo.show();
							var linkEl = Ext.get('showRequestErrorDetailInfo');
							if (linkEl) {
								linkEl.dom.innerHTML = stringList.getValue('Message.HideDetail');
							}
							if (memoEditValue) {
								memoEditDetailInfo.setValue(Ext.util.Format.htmlDecode(memoEditValue));
							}
							win.setHeight(win.getHeight() + detailsHeight - 5);
						} else {
							var linkEl = Ext.get('showRequestErrorDetailInfo');
							if (linkEl) {
								linkEl.dom.innerHTML = stringList.getValue('Message.Detail');
							}
							memoEditDetailInfo.hide();
							win.setHeight(win.getHeight() - detailsHeight + 5);
						}
					}, this);
				}
			}
		});
		var controllayout = new Terrasoft.ControlLayout({
			direction: 'horizontal',
			width: '100%',
			height: '100%'
		});
		var warningIcon = new Terrasoft.ImageBox({
			cls: "application-ico-error",
			width: 33,
			height: 32
		});
		var controllayoutBottom = new Terrasoft.ControlLayout({
			displayStyle: 'footer',
			width: '100%'
		});
		var spacer = new Ext.Spacer({
			size: '100%'
		});
		controllayoutBottom.add(spacer);
		controllayoutBottom.add(buttonOk);
		var controllayoutLeft = new Terrasoft.ControlLayout({
			width: 90,
			height: '100%'
		});
		var controllayoutRight = new Terrasoft.ControlLayout({
			cls: 'control-layout-right',
			width: '100%',
			height: '100%'
		});
		var labelInfo = new Terrasoft.Label({
			cls: 'x-label-black',
			caption: '<br />' + stringList.getValue('Message.OccuresAnError') + '<br /><br />' +
				'<b>' + stringList.getValue('Message.RequestFailure') + '</b><br /><br />' +
				'<a href="#" class="x-label" id="showRequestErrorDetailInfo">' + stringList.getValue('Message.Detail') + '</a><br /><br />'
		});
		controllayoutLeft.add(warningIcon);
		controllayoutRight.add(labelInfo);
		controllayoutRight.add(memoEditDetailInfo);
		controllayout.add(controllayoutLeft);
		controllayout.add(controllayoutRight);
		win.add(controllayout);
		win.add(controllayoutBottom);
		win.show();
		win.setHeight(185);
		var xy = win.el.getAlignToXY(win.container, 'c-c');
		win.setPagePosition(xy[0], xy[1] - 50);
	},

	parseResponse: function (response) {
		var text = response.responseText,
            xmlTpl = "<?xml",
            result = {},
            exception = false;
		result.success = true;

		try {
			if (response.responseText.match(/^<\?xml/) == xmlTpl) {

				//xml parsing      

				var xmlData = response.responseXML;
				var root = xmlData.documentElement || xmlData;
				var q = Ext.DomQuery;

				if (root.nodeName == "AjaxResponse") {

					//root = q.select("AjaxResponse", root);
					//success

					var sv = q.selectValue("Success", root, true);
					var pSuccess = sv !== false && sv !== "false",
                            pErrorMessage = q.selectValue("ErrorMessage", root, ""),
                            pScript = q.selectValue("Script", root, ""),
                            pViewState = q.selectValue("ViewState", root, ""),
                            pViewStateEncrypted = q.selectValue("ViewStateEncrypted", root, ""),
                            pEventValidation = q.selectValue("EventValidation", root, ""),
                            pServiceResponse = q.selectValue("ServiceResponse", root, ""),
                            pUserParamsResponse = q.selectValue("ExtraParamsResponse", root, ""),
                            pResult = q.selectValue("Result", root, "");

					if (!Ext.isEmpty(pSuccess)) {
						Ext.apply(result, { success: pSuccess });
					}
					if (!Ext.isEmpty(pErrorMessage)) {
						Ext.apply(result, { errorMessage: pErrorMessage });
					}
					if (!Ext.isEmpty(pScript)) {
						Ext.apply(result, { script: pScript });
					}
					if (!Ext.isEmpty(pViewState)) {
						Ext.apply(result, { viewState: pViewState });
					}
					if (!Ext.isEmpty(pViewStateEncrypted)) {
						Ext.apply(result, { viewStateEncrypted: pViewStateEncrypted });
					}
					if (!Ext.isEmpty(pEventValidation)) {
						Ext.apply(result, { eventValidation: pEventValidation });
					}
					if (!Ext.isEmpty(pServiceResponse)) {
						Ext.apply(result, { serviceResponse: eval("(" + pServiceResponse + ")") });
					}
					if (!Ext.isEmpty(pUserParamsResponse)) {
						Ext.apply(result, { extraParamsResponse: eval("(" + pUserParamsResponse + ")") });
					}
					if (!Ext.isEmpty(pResult)) {
						Ext.apply(result, { result: eval("(" + pResult + ")") });
					}
					return { result: result, exception: false };
				} else {
					return { result: response.responseXML, exception: false }; // root.text || root.textContent;
				}
			}
			if (text.indexOf("<!DOCTYPE html") === 0) {
				window.location.replace("ErrorPage.aspx");
			} else {

				//json parsing
				result = eval("(" + text + ")");
			}
		} catch (e) {
			result.success = false;
			exception = true;
			if (response.responseText.length === 0) {
				result.errorMessage = "NORESPONSE";
			} else {
				result.errorMessage = "BADRESPONSE: " + e.message;
				result.responseText = response.responseText;
			}
			response.statusText = result.errorMessage;
		}
		return { result: result, exception: exception };
	},

	listeners: {
		beforerequest: {
			fn: function (conn, options) {
				o = options || {};
				o.eventType = o.eventType || "event";
				var isStatic = o.eventType == "static",
					isInstance = o.eventType == "public",
					required = o.eventType == "pagemethod" || o.eventType == "event" || o.eventType == "custom" || o.eventType == "proxy" || o.eventType == "postback";
				var submitConfig = {};
				o.extraParams = o.extraParams || {};
				switch (o.eventType) {
					case "event":
					case "custom":
					case "proxy":
					case "postback":
					case "public":
					case "pagemethod":
						if (isInstance) {
							o.action = o.name;
						}
						o.control = o.control || {};
						o.type = o.type || "submit";
						o.viewStateMode = o.viewStateMode || "default";
						o.action = o.action || "Click";
						o.headers = { "X-Terrasoft": "delta=true" };
						if (o.type == "submit") {
							o.form = Ext.get(o.formProxyArg);
							if (Ext.isEmpty(o.form) && !Ext.isEmpty(o.control.el)) {
								if (Ext.isEmpty(o.control.isComposite) || o.control.isComposite === false) {
									o.form = o.control.el.up("form");
								} else {
									o.form = Ext.get(o.control.elements[0]).up("form");
								}
							}
						} else if (o.type == "load" && Ext.isEmpty(o.method)) {
							o.method = "GET";
						}
						if (Ext.isEmpty(o.form) && Ext.isEmpty(o.url)) {
							var forms = Ext.select("form").elements;
							if (forms.length > 0) {
								if (o.type == "submit") {
									o.form = Ext.get(forms[0]);
								} else {
									o.url = forms[0].dom.action || Terrasoft.Url || window.location.href;
								}
							}
						}
						var argument = String.format("{0}|{1}|{2}", o.proxyId || o.control.proxyId || o.control.id || "-", o.eventType, o.action);
						if (!Ext.isEmpty(o.form)) {
							this.setValue(o.form.dom, "__EVENTTARGET", Terrasoft.ScriptManagerUniqueID);
							this.setValue(o.form.dom, "__EVENTARGUMENT", argument);
							Ext.getDom(o.form).ignoreAllSubmitFields = true;
						} else {
							o.url = o.url || Terrasoft.Url || window.location.href;
							Ext.apply(submitConfig, { __EVENTTARGET: Terrasoft.ScriptManagerUniqueID, __EVENTARGUMENT: argument });
						}
						if (o.viewStateMode != "default") {
							Ext.apply(submitConfig, { viewStateMode: o.viewStateMode });
						}
						if (o.before) {
							if (o.before(o.control, o.eventType, o.action, o.extraParams) === false) {
								return false;
							}
						}
						Ext.apply(submitConfig, { extraParams: o.extraParams || {} });
						if (!Ext.isEmpty(o.serviceParams)) {
							Ext.apply(submitConfig, { serviceParams: o.serviceParams });
						}
						o.params = { submitAjaxEventConfig: Ext.encode({ config: submitConfig }) };
						if (!Ext.isEmpty(o.form)) {
							var enctype = Ext.getDom(o.form).getAttribute("enctype");
							if ((enctype && enctype.toLowerCase() == 'multipart/form-data') || o.isUpload) {
								Ext.apply(o.params, { "__TerrasoftAjaxEventMarker": "delta=true" });
							}
						}
						if (o.cleanRequest) {
							o.params = Ext.apply({}, o.extraParams || {});
						}
						if (!Ext.isEmpty(o.form)) {
							o.form.dom.action = o.form.dom.action || o.form.action || o.url || Terrasoft.Url || window.location.href;
						}
						break;
					case "static":
						o.headers = { "X-Terrasoft": "delta=true,staticmethod=true" };
						if (Ext.isEmpty(o.form) && Ext.isEmpty(o.url)) {
							var forms = Ext.select("form").elements;
							o.url = (forms.length > 0) ? forms[0].action : Terrasoft.Url || window.location.href;
						}
						if (o.before) {
							if (o.before(o.control, o.eventType, o.action, o.extraParams) === false) {
								return false;
							}
						}
						o.params = Ext.apply(o.extraParams, { "_methodName_": o.name });
						break;
				}
				o.callbackScope = o.scope || this;
				o.scope = this;

				//--Common part----------------------------------------------------------
				var el, em = o.eventMask || {};
				if (o.isUpload === true) {
					em.showMask = false;
				}
				if ((em.showMask === true)) {
					var targetElement = em.target || "page";
					switch (targetElement) {
						case "this":
							if (o.control.getEl) {
								el = o.control.getEl();
							} else if (o.control.dom) {
								el = o.control;
							}
							break;
						case "parent":
							if (o.control.getEl) {
								el = o.control.getEl().parent();
							} else if (o.control.parent) {
								el = o.control.parent();
							}
							break;
						case "page":
							el = Ext.getBody().createChild({
								"data-item-marker": "requestLoadingMask",
								style: "position:absolute;left:0;top:0;width:100%;height:100%;z-index:20000;background-color:Transparent;"
							});
							var scroll = Ext.getBody().getScroll();
							el.setLeftTop(scroll.left, scroll.top);
							break;
						case "customtarget":
							var trg = em.customTarget || "";
							el = Ext.get(trg);
							if (Ext.isEmpty(el)) {
								el = trg.getEl ? trg.getEl() : null;
							}
							break;
					}
					if (el !== undefined && el !== null) {
						var delay = 0 || em.startDelay;
						var isTopElement = targetElement == "page";
						setTimeout('Ext.EventManager.suspendBrowserEvents();', 20);
						if (em.showOpaqueMask) {
							el.mask('', "x-hide-display", em.isDynamicPosition == undefined ? true :
							em.isDynamicPosition, em.fitToElement == undefined ? false : em.fitToElement, true, '0.0',
							isTopElement);
						}
						var task = new Ext.util.DelayedTask(
							function () {
								if (em.showOpaqueMask) {
									el.unmask();
								}
								el.mask(em.msg || "test message", em.msgCls || "x-mask-loading",
									em.isDynamicPosition == undefined ? true : em.isDynamicPosition,
									em.fitToElement == undefined ? false : em.fitToElement, true, null, isTopElement);
							},
							o.scope,
							[o]
							).delay(delay);
						o.el = el;
						o.scope.maskEl = el;
					}
				}


				var removeMask = function (o) {
					if (o.el !== undefined && o.el !== null) {
						var delay = 0, em = o.eventMask || {};
						if (em && em.minDelay) {
							delay = em.minDelay;
						}
						Ext.EventManager.resumeBrowserEvents();
						var remove = (em.target || "page") == "page",
                            task = new Ext.util.DelayedTask(
                                function (o, remove) {
                                	o.scope.delayedF(o.el, remove);
                                },
                                o.scope,
                                [o, remove]
                            ).delay(delay);
					}
				};

				var executeScript = function (o, result, response) {
					var delay = 0;
					var em = o.eventMask || {};
					if (em.minDelay) {
						delay = em.minDelay;
					}
					var task = new Ext.util.DelayedTask(
                            function (o, result, response) {
                            	if (result.script && result.script.length > 0) {
                            		eval(result.script);
                            	}
                            	if (o.userSuccess) {
                            		o.userSuccess(response, result, o.control, o.eventType, o.action, o.extraParams, o);
                            	}
                            },
                            o.scope, [o, result, response]).delay(delay);
				};

				o.failure = function (response, options) {
					var o = options;
					removeMask(o);
					var preventDefaultProcessing = false;
					if (o.userFailure) {
						preventDefaultProcessing = (o.userFailure(response, {"errorMessage": response.statusText},
							o.control, o.eventType, o.action, o.extraParams, o));
					}
					if (preventDefaultProcessing) {
						return;
					} else {
						if (response.status != -1) {
							var parsedResponse = o.scope.parseResponse(response);
							if (parsedResponse.result.success !== false) {
								executeScript(o, parsedResponse.result, response);
							}
						} else if (o.showWarningOnFailure !== false) {
							o.scope.showFailure(response, "", o);
						}
					}
				};

				o.success = function (response, options) {
					var o = options;
					var scope = o.scope;
					try {
						var parsedResponse = o.scope.parseResponse(response);
						if (!Ext.isEmpty(parsedResponse.result.documentElement)) {
							executeScript(o, parsedResponse.result, response);
							return;
						}
						var result = parsedResponse.result;
						exception = parsedResponse.exception;
						if (result.success === false) {
							if (o.userFailure) {
								o.userFailure(response, result, o.control, o.eventType, o.action, o.extraParams, o);
							} else {
								if (o.showWarningOnFailure !== false) {
									var errorMsg = "";
									if (!exception && result.errorMessage && result.errorMessage.length > 0) {
										errorMsg = result.errorMessage;
									}
									scope.showFailure(response, errorMsg, o);
								}
							}
							return;
						}
						var form = o.form;
						var viewState = result.viewState;
						if (!Ext.isEmpty(viewState) && form !== null) {
							var dom = form.dom;
							var viewStateLength = viewState.length;
							scope.setValue(dom, "__VIEWSTATEFIELDCOUNT", viewStateLength);
							for (var i = 0; i < viewStateLength; i++) {
								scope.setValue(dom, "__VIEWSTATE" + i, viewState[i]);
							}
							if (!Ext.isEmpty(result.viewStateEncrypted)) {
								scope.setValue(dom, "__VIEWSTATEENCRYPTED", result.viewStateEncrypted);
							}
							if (!Ext.isEmpty(result.eventValidation)) {
								scope.setValue(dom, "__EVENTVALIDATION", result.eventValidation);
							}
						}
						executeScript(o, result, response);
					} finally {
						removeMask(o);
					}
				};
			}
		}
	}
});

Ext.ConfirmableAjaxEvent = new Ext.data.Connection({
	autoAbort: Ext.AjaxEvent.autoAbort,
	serializeForm: Ext.AjaxEvent.serializeForm,
	setValue: Ext.AjaxEvent.setValue,
	delayedF: Ext.AjaxEvent.delayedF,
	showFailure: Ext.AjaxEvent.showFailure,
	parseResponse: Ext.AjaxEvent.parseResponse,
	listeners: Ext.AjaxEvent.listeners,
	requestServer: function (o) {
		Ext.MessageBox.ajaxEventConfirm(o, o.confirmationTitle, o.confirmationMessage);
	}
});

Ext.AjaxMethod = {

	request: function (name, options) {
		options = options || {};
		if (typeof options !== "object") {
			throw { message: "The AjaxMethod options object is an invalid type: typeof " + typeof options };
		}
		if (!Ext.isEmpty(name) && typeof name === "object" && Ext.isEmptyObj(options)) {
			options = name;
		}
		var scope = options.scope;
		var obj = {
			name: options.name || name,
			control: Ext.isEmpty(options.control) ? null : { id: options.control },
			eventType: options.specifier || "public",
			type: options.type || "submit",
			async: options.async != false,
			method: options.method || "POST",
			eventMask: options.eventMask,
			extraParams: options.params,
			ajaxMethodSuccess: options.success,
			ajaxMethodFailure: options.failure,

			userSuccess: function (response, result, control, eventType, action, extraParams, o) {
				if (!Ext.isEmpty(o.ajaxMethodSuccess)) {
					var rez = Ext.isEmpty(result.result) ? result : result.result;
					if (Ext.isArray(result.result)) {
						rez = result.result;
					}
					o.ajaxMethodSuccess.call(scope || o, rez, response, extraParams);
				}
			},

			userFailure: function (response, result, control, eventType, action, extraParams, o) {
				if (!Ext.isEmpty(o.ajaxMethodFailure)) {
					return (o.ajaxMethodFailure.call(scope || o, result.errorMessage, response, extraParams)) === false;
				} 
			}
		};
		return Ext.AjaxEvent.request(Ext.apply(options, obj));
	}
};

Ext.HttpWriteProxy = function (conn) {
	Ext.HttpWriteProxy.superclass.constructor.call(this);
	this.conn = conn;
	this.useAjax = !conn || !conn.events;
	if (conn && conn.handleSaveResponseAsXml) {
		this.handleSaveResponseAsXml = conn.handleSaveResponseAsXml;
	}
};

Ext.extend(Ext.HttpWriteProxy, Ext.data.HttpProxy, {
	handleSaveResponseAsXml: false,
	save: function (params, reader, callback, scope, arg) {
		if (this.fireEvent("beforesave", this, params) !== false) {
			var o = {
				params: params || {},
				request: {
					callback: callback,
					scope: scope,
					arg: arg
				},
				reader: reader,
				scope: this,
				callback: this.saveResponse
			};
			if (this.useAjax) {
				Ext.applyIf(o, this.conn);
				if (this.activeRequest) {
					Ext.Ajax.abort(this.activeRequest);
				}
				this.activeRequest = Ext.Ajax.request(o);
			} else {
				this.conn.reequest(o);
			}
		} else {
			callback.call(scope || this, null, arg, false);
		}
	},

	saveResponse: function (o, success, response) {
		delete this.activeRequest;
		if (!success) {
			this.fireEvent("saveexception", this, o, response, { message: response.statusText });
			o.request.callback.call(o.request.scope, null, o.request.arg, false);
			return;
		}
		var result;
		try {
			if (!this.handleSaveResponseAsXml) {
				var json = response.responseText;
				var responseObj = eval("(" + json + ")");
				result = {
					success: responseObj.Success,
					msg: responseObj.Msg,
					data: responseObj.Data
				};
			}
			else {
				var doc = response.responseXML;
				var root = doc.documentElement || doc;
				var q = Ext.DomQuery;

				var sv = q.selectValue("Success", root, false);
				success = sv !== false && sv !== "false";
				var msg = q.selectValue("Msg", root, "");

				result = { success: success, msg: msg };
			}
		} catch (e) {
			this.fireEvent("saveexception", this, o, response, e);
			o.request.callback.call(o.request.scope, null, o.request.arg, false);
			return;
		}
		this.fireEvent("save", this, o, o.request.arg);
		o.request.callback.call(o.request.scope, result, o.request.arg, true);
	}
});

Ext.TaskResponse = { stopTask: -1, stopAjax: -2 };

Ext.TaskManager = function (config) {
	Ext.TaskManager.superclass.constructor.call(this);
	Ext.apply(this, config);
	return new Ext.util.DelayedTask(this.initManager, this).delay(this.autoRunDelay || 50);
};

Ext.extend(Ext.TaskManager, Ext.util.Observable, {
	tasksConfig: [],
	tasks: [],

	getTasks: function () {
		return this.tasks;
	},

	initManager: function () {
		this.runner = new Ext.util.TaskRunner(this.interval || 10);
		var task;
		for (var i = 0; i < this.tasksConfig.length; i++) {
			task = this.createTask(this.tasksConfig[i]);
			this.tasks.push(task);
			if (task.executing && task.autoRun) {
				this.startTask(task);
			}
		}
	},

	getTask: function (id) {
		if (typeof id == "object") {
			return id;
		} else if (typeof id == "string") {
			for (var i = 0; this.tasks.length; i++) {
				if (this.tasks[i].id == id) {
					return this.tasks[i];
				}
			}
		} else if (typeof id == "number") {
			return this.tasks[id];
		}
		return null;
	},

	startTask: function (task) {
		if (this.executing) {
			return;
		}
		task = this.getTask(task);
		if (task.onstart) {
			task.onstart.apply(task.scope || task);
		}
		this.runner.start(task);
	},

	stopTask: function (task) { this.runner.stop(this.getTask(task)); },

	startAll: function () {
		for (var i = 0; i < this.tasks.length; i++) {
			this.startTask(this.tasks[i]);
		}
	},

	stopAll: function () { this.runner.stopAll(); },

	//private

	createTask: function (config) {
		return Ext.apply({}, config, {
			owner: this,
			executing: true,
			interval: 1000,
			autoRun: true,

			onStop: function (t) {
				this.executing = false;
				if (this.onstop) {
					this.onstop();
				}
			},

			run: function () {
				if (this.clientRun) {
					var rt = this.clientRun.apply(arguments);
					if (rt === Ext.TaskResponse.stopAjax) {
						return;
					} else if (rt === Ext.TaskResponse.stopTask) {
						return false;
					}
				}
				if (this.serverRun) {
					var params = arguments;
					this.serverRun.control = this.owner;
					Ext.AjaxEvent.request(this.serverRun);
				}
			}
		});
	}
});

Ext.getCustomAttributes = function () {
	return Ext.util.JSON.decode(document.getElementById(Terrasoft.ScriptManagerUniqueID + "_Attributes").value);
};

Ext.LoadMask = function (el, config) {
	this.el = Ext.get(el);
	Ext.apply(this, config);
	var um = this.el.getUpdater();
	um.showLoadIndicator = false;
	um.on('beforeupdate', this.onBeforeLoad, this);
	um.on('update', this.onLoad, this);
	um.on('failure', this.onLoad, this);
	this.removeMask = Ext.value(this.removeMask, true);
};

Ext.LoadMask.prototype = {
	msgCls: 'x-mask-loading',
	isDynamicPosition: true,
	fitToElement: false,
	disabled: false,
	extCls: '',

	disable: function () {
		this.disabled = true;
	},

	enable: function () {
		this.disabled = false;
	},

	onLoad: function () {
		this.el.unmask(this.removeMask);
	},

	onBeforeLoad: function () {
		if (!this.disabled) {
			if (!this.msg) {
				this.msg = Ext.StringList('WC.Common').getValue('LoadMask.Loading');
			}
			var cls = this.msgCls + ' ' + this.extCls;
			this.el.mask(this.msg, cls, this.isDynamicPosition, this.fitToElement, this.isTransparent, this.opacity);
		}
	},

	show: function () {
		this.onBeforeLoad();
	},

	hide: function () {
		this.onLoad();
	},

	destroy: function () {
		var um = this.el.getUpdater();
		um.un('beforeupdate', this.onBeforeLoad, this);
		um.un('update', this.onLoad, this);
		um.un('failure', this.onLoad, this);
	}
};

if (typeof Sys !== "undefined") { Sys.Application.notifyScriptLoaded(); }
