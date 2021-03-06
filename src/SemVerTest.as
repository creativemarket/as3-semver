package {
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.setTimeout;

	public class SemVerTest extends Sprite {

		private var console:TextField;
		private var textFormat:TextFormat;
		private var count_passed:int = 0;
		private var count_failed:int = 0;
		private var messages:Array = [];

		public function SemVerTest() {
			stage.color = 0xf8ffe3;

			textFormat = new TextFormat();
			textFormat.font = "Arial";
			textFormat.size = 10;

			setTimeout(function():void { run(); }, 20);
		}

		private function invalidateConsole():void {
			if (console) removeChild(console);

			console = new TextField();
			console.htmlText = '';
			console.x = 0;
			console.y = 0;
			console.width = 500;
			console.height = 380;
			console.multiline = true;
			console.wordWrap = true;
			console.defaultTextFormat = textFormat;

			var count_total:int = count_passed + count_failed;
			console.htmlText = count_passed + ' of ' + count_total + ' tests passed (' + Math.round(count_passed / Number(count_total) * 100) + '%)<br>' + messages.join('<br>');

			addChild(console);
		}

		public function log(html:String):void {
			messages.push(html);
			invalidateConsole();
		}

		private function entities(str:String):String {
			return str.replace(/</g, '&lt;').replace(/>/g, '&gt;');
		}

		private function ok(result:Boolean, description:String):void {
			if (result) {
				log('<font color="#70cb0e">pass: ' + entities(description) + '</font>');
				count_passed++;
			} else {
				log('<font color="#e45000">fail: ' + entities(description) + ' should be <b>true</b></font>');
				stage.color = 0xffc0b2;
				count_failed++;
			}
		}

		private function equivalent(a:*, b:*):Boolean {
			if (typeof a !== typeof b) return false;
			if (a === b) return true;
			var typestr:String = typeof a;

			// scalars
			if (typestr === 'number' || typestr === 'boolean' || typestr === 'string' || typestr === 'function' || typestr === 'undefined' || (a === null || b === null)) {
				return a === b;
			}

			// objects + arrays
			if (!a && b) return false;
			if (a && !b) return false;
			if (!a && !b) return true;

			// arrays
			if (a is Array) {
				if (a.length !== b.length) return false;
				for (var i:int = 0; i < a.length; i++) {
					if (!equivalent(a[i], b[i])) return false;
				}
				return true;
			}

			// objects
			throw new Error('Object equivalence not supported.');
		}

		public function test_comparisons():void {
			var items:Array = [
				["0.0.0", "0.0.0foo"],
				["0.0.1", "0.0.0"],
				["1.0.0", "0.9.9"],
				["0.10.0", "0.9.0"],
				["0.99.0", "0.10.0"],
				["2.0.0", "1.2.3"],
				["v0.0.0", "0.0.0foo"],
				["v0.0.1", "0.0.0"],
				["v1.0.0", "0.9.9"],
				["v0.10.0", "0.9.0"],
				["v0.99.0", "0.10.0"],
				["v2.0.0", "1.2.3"],
				["0.0.0", "v0.0.0foo"],
				["0.0.1", "v0.0.0"],
				["1.0.0", "v0.9.9"],
				["0.10.0", "v0.9.0"],
				["0.99.0", "v0.10.0"],
				["2.0.0", "v1.2.3"],
				["1.2.3", "1.2.3-asdf"],
				["1.2.3-4", "1.2.3"],
				["1.2.3-4-foo", "1.2.3"],
				["1.2.3-5", "1.2.3-5-foo"],
				["1.2.3-5", "1.2.3-4"],
				["1.2.3-5-foo", "1.2.3-5-Foo"],
				["3.0.0", "2.7.2+"],
			];

			log('comparison:');
			for (var i:int = 0; i < items.length; i++) {
				var v:Array = items[i];
				// [version1, version2],
				// version1 should be greater than version2
				var v0:String = v[0];
				var v1:String = v[1];
				ok(SemVer.gt(v0, v1), "SemVer.gt('"+v0+"', '"+v1+"')");
				ok(SemVer.lt(v1, v0), "SemVer.lt('"+v1+"', '"+v0+"')");
				ok(!SemVer.gt(v1, v0), "!SemVer.gt('"+v1+"', '"+v0+"')");
				ok(!SemVer.lt(v0, v1), "!SemVer.lt('"+v0+"', '"+v1+"')");
				ok(SemVer.eq(v0, v0), "SemVer.eq('"+v0+"', '"+v0+"')");
				ok(SemVer.eq(v1, v1), "SemVer.eq('"+v1+"', '"+v1+"')");
				ok(SemVer.neq(v0, v1), "SemVer.neq('"+v0+"', '"+v1+"')");
				ok(SemVer.cmp(v1, "==", v1), "SemVer.cmp('"+v1+"' == '"+v1+"')");
				ok(SemVer.cmp(v0, ">=", v1), "SemVer.cmp('"+v0+"' >= '"+v1+"')");
				ok(SemVer.cmp(v1, "<=", v0), "SemVer.cmp('"+v1+"' <= '"+v0+"')");
				ok(SemVer.cmp(v0, "!=", v1), "SemVer.cmp('"+v0+"' != '"+v1+"')");
			}
		}

		public function test_equality():void {
			// [version1, version2],
			// version1 should be equivalent to version2
			var items:Array = [
				["1.2.3", "v1.2.3"],
				["1.2.3", "=1.2.3"],
				["1.2.3", "v 1.2.3"],
				["1.2.3", "= 1.2.3"],
				["1.2.3", " v1.2.3"],
				["1.2.3", " =1.2.3"],
				["1.2.3", " v 1.2.3"],
				["1.2.3", " = 1.2.3"],
				["1.2.3-0", "v1.2.3-0"],
				["1.2.3-0", "=1.2.3-0"],
				["1.2.3-0", "v 1.2.3-0"],
				["1.2.3-0", "= 1.2.3-0"],
				["1.2.3-0", " v1.2.3-0"],
				["1.2.3-0", " =1.2.3-0"],
				["1.2.3-0", " v 1.2.3-0"],
				["1.2.3-0", " = 1.2.3-0"],
				["1.2.3-01", "v1.2.3-1"],
				["1.2.3-01", "=1.2.3-1"],
				["1.2.3-01", "v 1.2.3-1"],
				["1.2.3-01", "= 1.2.3-1"],
				["1.2.3-01", " v1.2.3-1"],
				["1.2.3-01", " =1.2.3-1"],
				["1.2.3-01", " v 1.2.3-1"],
				["1.2.3-01", " = 1.2.3-1"],
				["1.2.3beta", "v1.2.3beta"],
				["1.2.3beta", "=1.2.3beta"],
				["1.2.3beta", "v 1.2.3beta"],
				["1.2.3beta", "= 1.2.3beta"],
				["1.2.3beta", " v1.2.3beta"],
				["1.2.3beta", " =1.2.3beta"],
				["1.2.3beta", " v 1.2.3beta"],
				["1.2.3beta", " = 1.2.3beta"],
			];

			log('equality:');
			for (var i:int = 0; i < items.length; i++) {
				var v:Array = items[i];
				var v0:String = v[0];
				var v1:String = v[1];

				ok(SemVer.eq(v0, v1), "SemVer.eq('"+v0+"', '"+v1+"')");
				ok(!SemVer.neq(v0, v1), "!SemVer.neq('"+v0+"', '"+v1+"')");
				ok(SemVer.cmp(v0, "==", v1), "SemVer.cmp("+v0+"=="+v1+")");
				ok(!SemVer.cmp(v0, "!=", v1), "!SemVer.cmp("+v0+"!="+v1+")");
				ok(!SemVer.cmp(v0, "===", v1), "!SemVer.cmp("+v0+"==="+v1+")");
				ok(SemVer.cmp(v0, "!==", v1), "SemVer.cmp("+v0+"!=="+v1+")");
				ok(!SemVer.gt(v0, v1), "!SemVer.gt('"+v0+"', '"+v1+"')");
				ok(SemVer.gte(v0, v1), "SemVer.gte('"+v0+"', '"+v1+"')");
				ok(!SemVer.lt(v0, v1), "!SemVer.lt('"+v0+"', '"+v1+"')");
				ok(SemVer.lte(v0, v1), "SemVer.lte('"+v0+"', '"+v1+"')");

			}
		}

		public function test_range():void {
			// [range, version],
			// version should be included by range
			var items:Array = [
				["1.0.0 - 2.0.0", "1.2.3"],
				["1.0.0", "1.0.0"],
				[">=*", "0.2.4"],
				["", "1.0.0"],
				["*", "1.2.3"],
				["*", "v1.2.3-foo"],
				[">=1.0.0", "1.0.0"],
				[">=1.0.0", "1.0.1"],
				[">=1.0.0", "1.1.0"],
				[">1.0.0", "1.0.1"],
				[">1.0.0", "1.1.0"],
				["<=2.0.0", "2.0.0"],
				["<=2.0.0", "1.9999.9999"],
				["<=2.0.0", "0.2.9"],
				["<2.0.0", "1.9999.9999"],
				["<2.0.0", "0.2.9"],
				[">= 1.0.0", "1.0.0"],
				[">=  1.0.0", "1.0.1"],
				[">=   1.0.0", "1.1.0"],
				["> 1.0.0", "1.0.1"],
				[">  1.0.0", "1.1.0"],
				["<=   2.0.0", "2.0.0"],
				["<= 2.0.0", "1.9999.9999"],
				["<=  2.0.0", "0.2.9"],
				["<    2.0.0", "1.9999.9999"],
				["<\t2.0.0", "0.2.9"],
				[">=0.1.97", "v0.1.97"],
				[">=0.1.97", "0.1.97"],
				["0.1.20 || 1.2.4", "1.2.4"],
				[">=0.2.3 || <0.0.1", "0.0.0"],
				[">=0.2.3 || <0.0.1", "0.2.3"],
				[">=0.2.3 || <0.0.1", "0.2.4"],
				["||", "1.3.4"],
				["2.x.x", "2.1.3"],
				["1.2.x", "1.2.3"],
				["1.2.x || 2.x", "2.1.3"],
				["1.2.x || 2.x", "1.2.3"],
				["x", "1.2.3"],
				["2.*.*", "2.1.3"],
				["1.2.*", "1.2.3"],
				["1.2.* || 2.*", "2.1.3"],
				["1.2.* || 2.*", "1.2.3"],
				["*", "1.2.3"],
				["2", "2.1.2"],
				["2.3", "2.3.1"],
				["~2.4", "2.4.0"], // >=2.4.0 <2.5.0
				["~2.4", "2.4.5"],
				["~>3.2.1", "3.2.2"], // >=3.2.1 <3.3.0
				["~1", "1.2.3"], // >=1.0.0 <2.0.0
				["~>1", "1.2.3"],
				["~> 1", "1.2.3"],
				["~1.0", "1.0.2"], // >=1.0.0 <1.1.0
				["~ 1.0", "1.0.2"],
				["~ 1.0.3", "1.0.12"],
				[">=1", "1.0.0"],
				[">= 1", "1.0.0"],
				["<1.2", "1.1.1"],
				["< 1.2", "1.1.1"],
				["1", "1.0.0beta"],
				["~v0.5.4-pre", "0.5.5"],
				["~v0.5.4-pre", "0.5.4"],
				["=0.7.x", "0.7.2"],
				[">=0.7.x", "0.7.2"],
				["=0.7.x", "0.7.0-asdf"],
				[">=0.7.x", "0.7.0-asdf"],
				["<=0.7.x", "0.6.2"],
				["~1.2.1 >=1.2.3", "1.2.3"],
				["~1.2.1 =1.2.3", "1.2.3"],
				["~1.2.1 1.2.3", "1.2.3"],
				['~1.2.1 >=1.2.3 1.2.3', '1.2.3'],
				['~1.2.1 1.2.3 >=1.2.3', '1.2.3'],
				['~1.2.1 1.2.3', '1.2.3'],
				['>=1.2.1 1.2.3', '1.2.3'],
				['1.2.3 >=1.2.1', '1.2.3'],
				['>=1.2.3 >=1.2.1', '1.2.3'],
				['>=1.2.1 >=1.2.3', '1.2.3']
			];

			log('range:');
			for (var i:int = 0; i < items.length; i++) {
				var v:Array = items[i];
				var v0:String = v[0];
				var v1:String = v[1];

				ok(SemVer.satisfies(v[1], v[0]), v[0]+" satisfied by "+v[1]);
			}
		}

		public function test_range_negative():void {
			// [range, version],
			// version should not be included by range
			var items:Array = [
				["1.0.0 - 2.0.0", "2.2.3"],
				["1.0.0", "1.0.1"],
				[">=1.0.0", "0.0.0"],
				[">=1.0.0", "0.0.1"],
				[">=1.0.0", "0.1.0"],
				[">1.0.0", "0.0.1"],
				[">1.0.0", "0.1.0"],
				["<=2.0.0", "3.0.0"],
				["<=2.0.0", "2.9999.9999"],
				["<=2.0.0", "2.2.9"],
				["<2.0.0", "2.9999.9999"],
				["<2.0.0", "2.2.9"],
				[">=0.1.97", "v0.1.93"],
				[">=0.1.97", "0.1.93"],
				["0.1.20 || 1.2.4", "1.2.3"],
				[">=0.2.3 || <0.0.1", "0.0.3"],
				[">=0.2.3 || <0.0.1", "0.2.2"],
				["2.x.x", "1.1.3"],
				["2.x.x", "3.1.3"],
				["1.2.x", "1.3.3"],
				["1.2.x || 2.x", "3.1.3"],
				["1.2.x || 2.x", "1.1.3"],
				["2.*.*", "1.1.3"],
				["2.*.*", "3.1.3"],
				["1.2.*", "1.3.3"],
				["1.2.* || 2.*", "3.1.3"],
				["1.2.* || 2.*", "1.1.3"],
				["2", "1.1.2"],
				["2.3", "2.4.1"],
				["~2.4", "2.5.0"], // >=2.4.0 <2.5.0
				["~2.4", "2.3.9"],
				["~>3.2.1", "3.3.2"], // >=3.2.1 <3.3.0
				["~>3.2.1", "3.2.0"], // >=3.2.1 <3.3.0
				["~1", "0.2.3"], // >=1.0.0 <2.0.0
				["~>1", "2.2.3"],
				["~1.0", "1.1.0"], // >=1.0.0 <1.1.0
				["<1", "1.0.0"],
				[">=1.2", "1.1.1"],
				["1", "2.0.0beta"],
				["~v0.5.4-beta", "0.5.4-alpha"],
				["<1", "1.0.0beta"],
				["< 1", "1.0.0beta"],
				["=0.7.x", "0.8.2"],
				[">=0.7.x", "0.6.2"],
				["<=0.7.x", "0.7.2"]
			];

			log('negative range:');
			for (var i:int = 0; i < items.length; i++) {
				var v:Array = items[i];
				var v0:String = v[0];
				var v1:String = v[1];

				ok(!SemVer.satisfies(v[1], v[0]), v[0]+" not satisfied by "+v[1]);
			}
		}

		public function test_increment_version():void {
			// [version, inc, result],
			// inc(version, inc) -> result
			var items:Array = [
				["1.2.3", "major", "2.0.0"],
				["1.2.3", "minor", "1.3.0"],
				["1.2.3", "patch", "1.2.4"],
				["1.2.3", "build", "1.2.3-1"],
				["1.2.3-4", "build", "1.2.3-5"],
				["1.2.3tag", "major", "2.0.0"],
				["1.2.3-tag", "major", "2.0.0"],
				["1.2.3tag", "build", "1.2.3-1"],
				["1.2.3-tag", "build", "1.2.3-1"],
				["1.2.3-4-tag", "build", "1.2.3-5"],
				["1.2.3-4tag", "build", "1.2.3-5"],
				["1.2.3", "fake", null],
				["fake", "major", null ]
			];

			log('increment version:');
			for (var i:int = 0; i < items.length; i++) {
				var v:Array = items[i];
				ok(SemVer.inc(v[0], v[1]) === v[2], "SemVer.inc("+v[0]+", "+v[1]+") === "+v[2]);
			}
		}

		public function test_replace_stars():void {
			// replace stars with ""
			var items:Array = [
				["", ""],
				["*", ""],
				["> *", ""],
				["<*", ""],
				[" >=  *", ""],
				["* || 1.2.3", " || 1.2.3"]
			];

			log('replace stars:');
			for (var i:int = 0; i < items.length; i++) {
				var v:Array = items[i];
				ok(SemVer.replaceStars(v[0]) === v[1], "SemVer.replaceStars("+v[0]+") === \""+v[1]+"\" ... " + SemVer.replaceStars(v[0]));
			}
		}

		public function test_valid_range():void {
			// [range, result],
			// validRange(range) -> result
			// translate ranges into their canonical form
			var items:Array = [
				["1.0.0 - 2.0.0", ">=1.0.0 <=2.0.0"],
				["1.0.0", "1.0.0"],
				[">=*", ""],
				["", ""],
				["*", ""],
				["*", ""],
				[">=1.0.0", ">=1.0.0"],
				[">1.0.0", ">1.0.0"],
				["<=2.0.0", "<=2.0.0"],
				["1", ">=1.0.0- <2.0.0-"],
				["<=2.0.0", "<=2.0.0"],
				["<=2.0.0", "<=2.0.0"],
				["<2.0.0", "<2.0.0"],
				["<2.0.0", "<2.0.0"],
				[">= 1.0.0", ">=1.0.0"],
				[">=  1.0.0", ">=1.0.0"],
				[">=   1.0.0", ">=1.0.0"],
				["> 1.0.0", ">1.0.0"],
				[">  1.0.0", ">1.0.0"],
				["<=   2.0.0", "<=2.0.0"],
				["<= 2.0.0", "<=2.0.0"],
				["<=  2.0.0", "<=2.0.0"],
				["<    2.0.0", "<2.0.0"],
				["<	2.0.0", "<2.0.0"],
				[">=0.1.97", ">=0.1.97"],
				[">=0.1.97", ">=0.1.97"],
				["0.1.20 || 1.2.4", "0.1.20||1.2.4"],
				[">=0.2.3 || <0.0.1", ">=0.2.3||<0.0.1"],
				[">=0.2.3 || <0.0.1", ">=0.2.3||<0.0.1"],
				[">=0.2.3 || <0.0.1", ">=0.2.3||<0.0.1"],
				["||", "||"],
				["2.x.x", ">=2.0.0- <3.0.0-"],
				["1.2.x", ">=1.2.0- <1.3.0-"],
				["1.2.x || 2.x", ">=1.2.0- <1.3.0-||>=2.0.0- <3.0.0-"],
				["1.2.x || 2.x", ">=1.2.0- <1.3.0-||>=2.0.0- <3.0.0-"],
				["x", ""],
				["2.*.*", null],
				["1.2.*", null],
				["1.2.* || 2.*", null],
				["1.2.* || 2.*", null],
				["*", ""],
				["2", ">=2.0.0- <3.0.0-"],
				["2.3", ">=2.3.0- <2.4.0-"],
				["~2.4", ">=2.4.0- <2.5.0-"],
				["~2.4", ">=2.4.0- <2.5.0-"],
				["~>3.2.1", ">=3.2.1- <3.3.0-"],
				["~1", ">=1.0.0- <2.0.0-"],
				["~>1", ">=1.0.0- <2.0.0-"],
				["~> 1", ">=1.0.0- <2.0.0-"],
				["~1.0", ">=1.0.0- <1.1.0-"],
				["~ 1.0", ">=1.0.0- <1.1.0-"],
				["<1", "<1.0.0-"],
				["< 1", "<1.0.0-"],
				[">=1", ">=1.0.0-"],
				[">= 1", ">=1.0.0-"],
				["<1.2", "<1.2.0-"],
				["< 1.2", "<1.2.0-"],
				["1", ">=1.0.0- <2.0.0-"]
			];

			log('valid range:');
			for (var i:int = 0; i < items.length; i++) {
				var v:Array = items[i];
				ok(SemVer.validRange(v[0]) === v[1], "SemVer.validRange("+v[0]+") === "+v[1]);
			}
		}

		public function test_comparators():void {
			// [range, comparators],
			// turn range into a set of individual comparators
			var items:Array = [
				["1.0.0 - 2.0.0", [[">=1.0.0", "<=2.0.0"]]],
				["1.0.0", [["1.0.0"]]],
				[">=*", [[">=0.0.0-"]]],
				["", [[""]]],
				["*", [[""]]],
				["*", [[""]]],
				[">=1.0.0", [[">=1.0.0"]]],
				[">=1.0.0", [[">=1.0.0"]]],
				[">=1.0.0", [[">=1.0.0"]]],
				[">1.0.0", [[">1.0.0"]]],
				[">1.0.0", [[">1.0.0"]]],
				["<=2.0.0", [["<=2.0.0"]]],
				["1", [[">=1.0.0-", "<2.0.0-"]]],
				["<=2.0.0", [["<=2.0.0"]]],
				["<=2.0.0", [["<=2.0.0"]]],
				["<2.0.0", [["<2.0.0"]]],
				["<2.0.0", [["<2.0.0"]]],
				[">= 1.0.0", [[">=1.0.0"]]],
				[">=  1.0.0", [[">=1.0.0"]]],
				[">=   1.0.0", [[">=1.0.0"]]],
				["> 1.0.0", [[">1.0.0"]]],
				[">  1.0.0", [[">1.0.0"]]],
				["<=   2.0.0", [["<=2.0.0"]]],
				["<= 2.0.0", [["<=2.0.0"]]],
				["<=  2.0.0", [["<=2.0.0"]]],
				["<    2.0.0", [["<2.0.0"]]],
				["<\t2.0.0", [["<2.0.0"]]],
				[">=0.1.97", [[">=0.1.97"]]],
				[">=0.1.97", [[">=0.1.97"]]],
				["0.1.20 || 1.2.4", [["0.1.20"], ["1.2.4"]]],
				[">=0.2.3 || <0.0.1", [[">=0.2.3"], ["<0.0.1"]]],
				[">=0.2.3 || <0.0.1", [[">=0.2.3"], ["<0.0.1"]]],
				[">=0.2.3 || <0.0.1", [[">=0.2.3"], ["<0.0.1"]]],
				["||", [[""], [""]]],
				["2.x.x", [[">=2.0.0-", "<3.0.0-"]]],
				["1.2.x", [[">=1.2.0-", "<1.3.0-"]]],
				["1.2.x || 2.x", [[">=1.2.0-", "<1.3.0-"], [">=2.0.0-", "<3.0.0-"]]],
				["1.2.x || 2.x", [[">=1.2.0-", "<1.3.0-"], [">=2.0.0-", "<3.0.0-"]]],
				["x", [[""]]],
				["2.*.*", [[">=2.0.0-", "<3.0.0-"]]],
				["1.2.*", [[">=1.2.0-", "<1.3.0-"]]],
				["1.2.* || 2.*", [[">=1.2.0-", "<1.3.0-"], [">=2.0.0-", "<3.0.0-"]]],
				["1.2.* || 2.*", [[">=1.2.0-", "<1.3.0-"], [">=2.0.0-", "<3.0.0-"]]],
				["*", [[""]]],
				["2", [[">=2.0.0-", "<3.0.0-"]]],
				["2.3", [[">=2.3.0-", "<2.4.0-"]]],
				["~2.4", [[">=2.4.0-", "<2.5.0-"]]],
				["~2.4", [[">=2.4.0-", "<2.5.0-"]]],
				["~>3.2.1", [[">=3.2.1-", "<3.3.0-"]]],
				["~1", [[">=1.0.0-", "<2.0.0-"]]],
				["~>1", [[">=1.0.0-", "<2.0.0-"]]],
				["~> 1", [[">=1.0.0-", "<2.0.0-"]]],
				["~1.0", [[">=1.0.0-", "<1.1.0-"]]],
				["~ 1.0", [[">=1.0.0-", "<1.1.0-"]]],
				["~ 1.0.3", [[">=1.0.3-", "<1.1.0-"]]],
				["~> 1.0.3", [[">=1.0.3-", "<1.1.0-"]]],
				["<1", [["<1.0.0-"]]],
				["< 1", [["<1.0.0-"]]],
				[">=1", [[">=1.0.0-"]]],
				[">= 1", [[">=1.0.0-"]]],
				["<1.2", [["<1.2.0-"]]],
				["< 1.2", [["<1.2.0-"]]],
				["1", [[">=1.0.0-", "<2.0.0-"]]],
				["1 2", [[">=1.0.0-", "<2.0.0-", ">=2.0.0-", "<3.0.0-"]]]
			];

			log('comparators:');
			for (var i:int = 0; i < items.length; i++) {
				var v:Array = items[i];
				ok(equivalent(SemVer.toComparators(v[0]), v[1]), "SemVer.toComparators("+v[0]+") equivalence to expected result");
			}
		}

		public function run():void {
			test_comparisons();
			test_equality();
			test_range();
			test_range_negative();
			test_increment_version();
			test_replace_stars();
			test_valid_range();
			test_comparators();
		}

	}
}