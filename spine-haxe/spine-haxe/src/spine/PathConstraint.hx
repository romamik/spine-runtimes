/******************************************************************************
 * Spine Runtimes Software License v2.5
 *
 * Copyright (c) 2013-2016, Esoteric Software
 * All rights reserved.
 *
 * You are granted a perpetual, non-exclusive, non-sublicensable, and
 * non-transferable license to use, install, execute, and perform the Spine
 * Runtimes software and derivative works solely for personal or internal
 * use. Without the written permission of Esoteric Software (see Section 2 of
 * the Spine Software License Agreement), you may not (a) modify, translate,
 * adapt, or develop new applications using the Spine Runtimes or otherwise
 * create derivative works or improvements of the Spine Runtimes or (b) remove,
 * delete, alter, or obscure any trademarks or any copyright, trademark, patent,
 * or other intellectual property or proprietary rights notices on or in the
 * Software, including any copy thereof. Redistributions in binary or source
 * form must include this license and terms.
 *
 * THIS SOFTWARE IS PROVIDED BY ESOTERIC SOFTWARE "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL ESOTERIC SOFTWARE BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES, BUSINESS INTERRUPTION, OR LOSS OF
 * USE, DATA, OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
 * IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/

package spine;
import spine.attachments.PathAttachment;

class PathConstraint implements Updatable {
	private static inline var NONE:Int = -1; private static inline var BEFORE:Int = -2; private static inline var AFTER:Int = -3;

	@:allow(spine) var _data:PathConstraintData;
	@:allow(spine) var _bones:Vector<Bone>;
	public var target:Slot;
	public var position:Number; public var spacing:Number; public var rotateMix:Number; public var translateMix:Number;

	@:allow(spine) var _spaces(default, null):Vector<Number> = new Vector<Number>();
	@:allow(spine) var _positions(default, null):Vector<Number> = new Vector<Number>();
	@:allow(spine) var _world(default, null):Vector<Number> = new Vector<Number>();
	@:allow(spine) var _curves(default, null):Vector<Number> = new Vector<Number>();
	@:allow(spine) var _lengths(default, null):Vector<Number> = new Vector<Number>();
	@:allow(spine) var _segments(default, null):Vector<Number> = new Vector<Number>(10);	

	public function new (data:PathConstraintData, skeleton:Skeleton) {
		if (data == null) throw new ArgumentError("data cannot be null.");
		if (skeleton == null) throw new ArgumentError("skeleton cannot be null.");
		_data = data;
		_bones = new Vector<Bone>();		
		for (boneData in data.bones)
			_bones.push(skeleton.findBone(boneData.name));
		target = skeleton.findSlot(data.target.name);
		position = data.position;
		spacing = data.spacing;
		rotateMix = data.rotateMix;
		translateMix = data.translateMix;
	}

	public function apply () : Void {
		update();
	}
	
	public function update () : Void {
		var attachment:PathAttachment = Std.instance(target.attachment, PathAttachment);
		if (attachment == null) return;		

		var rotateMix:Number = this.rotateMix, translateMix:Number = this.translateMix;
		var translate:Bool = translateMix > 0, rotate:Bool = rotateMix > 0;
		if (!translate && !rotate) return;

		var data:PathConstraintData = this._data;
		var spacingMode:SpacingMode = data.spacingMode;
		var lengthSpacing:Bool = spacingMode == SpacingMode.length;
		var rotateMode:RotateMode = data.rotateMode;
		var tangents:Bool = rotateMode == RotateMode.tangent, scale:Bool = rotateMode == RotateMode.chainScale;
		var boneCount:Int = this._bones.length, spacesCount:Int = tangents ? boneCount : boneCount + 1;
		var bones:Vector<Bone> = this._bones;
		this._spaces.length = spacesCount;
		var spaces:Vector<Number> = this._spaces, lengths:Vector<Number> = null;
		var spacing:Number = this.spacing;
		if (scale || lengthSpacing) {
			if (scale) {
				this._lengths.length = boneCount;
				lengths = this._lengths;
			}
			var i:Int = 0, n:Int = spacesCount - 1;
			while (i < n) {
				var bone:Bone = bones[i];
				var length:Number = bone.data.length, x:Number = length * bone.a, y:Number = length * bone.c;
				length = Math.sqrt(x * x + y * y);
				if (scale) lengths[i] = length;
				spaces[++i] = lengthSpacing ? Math.max(0, length + spacing) : spacing;
			}
		} else {
			for (i in 1...spacesCount)
				spaces[i] = spacing;
		}

		var positions:Vector<Number> = computeWorldPositions(attachment, spacesCount, tangents,
			data.positionMode == PositionMode.percent, spacingMode == SpacingMode.percent);
		var skeleton:Skeleton = target.skeleton;
		var skeletonX:Number = skeleton.x, skeletonY:Number = skeleton.y;
		var boneX:Number = positions[0], boneY:Number = positions[1], offsetRotation:Number = data.offsetRotation;
		var tip:Bool = rotateMode == RotateMode.chain && offsetRotation == 0;
		var p:Number;
		var i:Int = 0, p:Int = 3;
		while (i < boneCount) {
			var bone:Bone = bones[i];
			bone._worldX += (boneX - skeletonX - bone.worldX) * translateMix;
			bone._worldY += (boneY - skeletonY - bone.worldY) * translateMix;
			var x:Number = positions[p]; var y:Number = positions[p + 1]; var dx:Number = x - boneX, dy:Number = y - boneY;
			if (scale) {
				var length:Number = lengths[i];
				if (length != 0) {
					var s:Number = (Math.sqrt(dx * dx + dy * dy) / length - 1) * rotateMix + 1;
					bone._a *= s;
					bone._c *= s;
				}
			}
			boneX = x;
			boneY = y;
			if (rotate) {
				var a:Number = bone.a, b:Number = bone.b, c:Number = bone.c, d:Number = bone.d, r:Number, cos:Number, sin:Number;
				if (tangents)
					r = positions[p - 1];
				else if (spaces[i + 1] == 0)
					r = positions[p + 2];
				else
					r = Math.atan2(dy, dx);
				r -= Math.atan2(c, a) - offsetRotation * MathUtils.degRad;
				if (tip) {
					cos = Math.cos(r);
					sin = Math.sin(r);
					var length:Number = bone.data.length;
					boneX += (length * (cos * a - sin * c) - dx) * rotateMix;
					boneY += (length * (sin * a + cos * c) - dy) * rotateMix;
				}
				if (r > Math.PI)
					r -= (Math.PI * 2);
				else if (r < -Math.PI) //
					r += (Math.PI * 2);
				r *= rotateMix;
				cos = Math.cos(r);
				sin = Math.sin(r);
				bone._a = cos * a - sin * c;
				bone._b = cos * b - sin * d;
				bone._c = sin * a + cos * c;
				bone._d = sin * b + cos * d;
			}
			i++; p += 3;
		}
	}

	private function computeWorldPositions (path:PathAttachment, spacesCount:Int, tangents:Bool, percentPosition:Bool,
		percentSpacing:Bool) : Vector<Number> {
		var target:Slot = this.target;
		var position:Number = this.position;
		var spaces:Vector<Number> = this._spaces;
		this._positions.length = spacesCount * 3 + 2;
		var out:Vector<Number> = this._positions, world:Vector<Number>;
		var closed:Bool = path.closed;
		var verticesLength:Int = path.worldVerticesLength, curveCount:Int = int(verticesLength / 6), prevCurve:Int = NONE;

		if (!path.constantSpeed) {
			var lengths:Vector<Number> = path.lengths;
			curveCount -= closed ? 1 : 2;
			var pathLength:Number = lengths[curveCount];
			if (percentPosition) position *= pathLength;
			if (percentSpacing) {
				for (i in 0...spacesCount)
					spaces[i] *= pathLength;
			}
			this._world.length = 8;
			world = this._world;
			var o:Int = 0, curve:Int = 0, i:Int = 0;
			i--; o -= 3; while (i + 1 < spacesCount) { i++; o += 3;
				var space:Number = spaces[i];
				position += space;
				var p:Number = position;

				if (closed) {
					p %= pathLength;
					if (p < 0) p += pathLength;
					curve = 0;
				} else if (p < 0) {
					if (prevCurve != BEFORE) {
						prevCurve = BEFORE;
						path.computeWorldVertices2(target, 2, 4, world, 0);
					}
					addBeforePosition(p, world, 0, out, o);
					continue;
				} else if (p > pathLength) {
					if (prevCurve != AFTER) {
						prevCurve = AFTER;
						path.computeWorldVertices2(target, verticesLength - 6, 4, world, 0);
					}
					addAfterPosition(p - pathLength, world, 0, out, o);
					continue;
				}

				// Determine curve containing position.
				curve--; while (true) { curve++;
					var length:Number = lengths[curve];
					if (p > length) continue;
					if (curve == 0)
						p /= length;
					else {
						var prev:Number = lengths[curve - 1];
						p = (p - prev) / (length - prev);
					}
					break;
				}
				if (curve != prevCurve) {
					prevCurve = curve;
					if (closed && curve == curveCount) {
						path.computeWorldVertices2(target, verticesLength - 4, 4, world, 0);
						path.computeWorldVertices2(target, 0, 4, world, 4);
					} else
						path.computeWorldVertices2(target, curve * 6 + 2, 8, world, 0);
				}
				addCurvePosition(p, world[0], world[1], world[2], world[3], world[4], world[5], world[6], world[7], out, o,
					tangents || (i > 0 && space == 0));
			}
			return out;
		}

		// World vertices.
		if (closed) {
			verticesLength += 2;
			this._world.length = verticesLength;
			world = this._world;
			path.computeWorldVertices2(target, 2, verticesLength - 4, world, 0);
			path.computeWorldVertices2(target, 0, 2, world, verticesLength - 4);
			world[verticesLength - 2] = world[0];
			world[verticesLength - 1] = world[1];
		} else {
			curveCount--;
			verticesLength -= 4;
			this._world.length = verticesLength;
			world = this._world;
			path.computeWorldVertices2(target, 2, verticesLength, world, 0);
		}

		// Curve lengths.
		this._curves.length = curveCount;
		var curves:Vector<Number> = this._curves;
		var pathLength:Number = 0;
		var x1:Number = world[0], y1:Number = world[1], cx1:Number = 0, cy1:Number = 0, cx2:Number = 0, cy2:Number = 0, x2:Number = 0, y2:Number = 0;
		var tmpx:Number, tmpy:Number, dddfx:Number, dddfy:Number, ddfx:Number, ddfy:Number, dfx:Number, dfy:Number;
		var w:Int = 2, i:Int = 0;
		while (i < curveCount) {
			cx1 = world[w];
			cy1 = world[w + 1];
			cx2 = world[w + 2];
			cy2 = world[w + 3];
			x2 = world[w + 4];
			y2 = world[w + 5];
			tmpx = (x1 - cx1 * 2 + cx2) * 0.1875;
			tmpy = (y1 - cy1 * 2 + cy2) * 0.1875;
			dddfx = ((cx1 - cx2) * 3 - x1 + x2) * 0.09375;
			dddfy = ((cy1 - cy2) * 3 - y1 + y2) * 0.09375;
			ddfx = tmpx * 2 + dddfx;
			ddfy = tmpy * 2 + dddfy;
			dfx = (cx1 - x1) * 0.75 + tmpx + dddfx * 0.16666667;
			dfy = (cy1 - y1) * 0.75 + tmpy + dddfy * 0.16666667;
			pathLength += Math.sqrt(dfx * dfx + dfy * dfy);
			dfx += ddfx;
			dfy += ddfy;
			ddfx += dddfx;
			ddfy += dddfy;
			pathLength += Math.sqrt(dfx * dfx + dfy * dfy);
			dfx += ddfx;
			dfy += ddfy;
			pathLength += Math.sqrt(dfx * dfx + dfy * dfy);
			dfx += ddfx + dddfx;
			dfy += ddfy + dddfy;
			pathLength += Math.sqrt(dfx * dfx + dfy * dfy);
			curves[i] = pathLength;
			x1 = x2;
			y1 = y2;
			i++; w += 6;
		}
		if (percentPosition) position *= pathLength;
		if (percentSpacing) {
			for (i in 0...spacesCount)
				spaces[i] *= pathLength;
		}

		var segments:Vector<Number> = this._segments;
		var curveLength:Number = 0;
		var segment:Int, i:Int = 0, o:Int = 0, curve:Int = 0, segment:Int = 0;
		i--; o -= 3; while (i + 1 < spacesCount) { i++; o += 3;
			var space:Number = spaces[i];
			position += space;
			var p:Number = position;

			if (closed) {
				p %= pathLength;
				if (p < 0) p += pathLength;
				curve = 0;
			} else if (p < 0) {
				addBeforePosition(p, world, 0, out, o);
				continue;
			} else if (p > pathLength) {
				addAfterPosition(p - pathLength, world, verticesLength - 4, out, o);
				continue;
			}

			// Determine curve containing position.
			curve--; while (true) { curve++;
				var length:Number = curves[curve];
				if (p > length) continue;
				if (curve == 0)
					p /= length;
				else {
					var prev:Number = curves[curve - 1];
					p = (p - prev) / (length - prev);
				}
				break;
			}

			// Curve segment lengths.
			if (curve != prevCurve) {
				prevCurve = curve;
				var ii:Int = curve * 6;
				x1 = world[ii];
				y1 = world[ii + 1];
				cx1 = world[ii + 2];
				cy1 = world[ii + 3];
				cx2 = world[ii + 4];
				cy2 = world[ii + 5];
				x2 = world[ii + 6];
				y2 = world[ii + 7];
				tmpx = (x1 - cx1 * 2 + cx2) * 0.03;
				tmpy = (y1 - cy1 * 2 + cy2) * 0.03;
				dddfx = ((cx1 - cx2) * 3 - x1 + x2) * 0.006;
				dddfy = ((cy1 - cy2) * 3 - y1 + y2) * 0.006;
				ddfx = tmpx * 2 + dddfx;
				ddfy = tmpy * 2 + dddfy;
				dfx = (cx1 - x1) * 0.3 + tmpx + dddfx * 0.16666667;
				dfy = (cy1 - y1) * 0.3 + tmpy + dddfy * 0.16666667;
				curveLength = Math.sqrt(dfx * dfx + dfy * dfy);
				segments[0] = curveLength;
				for (ii in 1...8) {
					dfx += ddfx;
					dfy += ddfy;
					ddfx += dddfx;
					ddfy += dddfy;
					curveLength += Math.sqrt(dfx * dfx + dfy * dfy);
					segments[ii] = curveLength;
				}
				dfx += ddfx;
				dfy += ddfy;
				curveLength += Math.sqrt(dfx * dfx + dfy * dfy);
				segments[8] = curveLength;
				dfx += ddfx + dddfx;
				dfy += ddfy + dddfy;
				curveLength += Math.sqrt(dfx * dfx + dfy * dfy);
				segments[9] = curveLength;
				segment = 0;
			}

			// Weight by segment length.
			p *= curveLength;
			segment--; while (true) { segment++;
				var length:Number = segments[segment];
				if (p > length) continue;
				if (segment == 0)
					p /= length;
				else {
					var prev:Number = segments[segment - 1];
					var p:Number = segment + (p - prev) / (length - prev);
				}
				break;
			}
			addCurvePosition(p * 0.1, x1, y1, cx1, cy1, cx2, cy2, x2, y2, out, o, tangents || (i > 0 && space == 0));
		}
		return out;
	}

	private function addBeforePosition (p:Number, temp:Vector<Number>, i:Int, out:Vector<Number>, o:Int) : Void {
		var x1:Number = temp[i], y1:Number = temp[i + 1], dx:Number = temp[i + 2] - x1, dy:Number = temp[i + 3] - y1, r:Number = Math.atan2(dy, dx);
		out[o] = x1 + p * Math.cos(r);
		out[o + 1] = y1 + p * Math.sin(r);
		out[o + 2] = r;
	}

	private function addAfterPosition (p:Number, temp:Vector<Number>, i:Int, out:Vector<Number>, o:Int) : Void {
		var x1:Number = temp[i + 2], y1:Number = temp[i + 3], dx:Number = x1 - temp[i], dy:Number = y1 - temp[i + 1], r:Number = Math.atan2(dy, dx);
		out[o] = x1 + p * Math.cos(r);
		out[o + 1] = y1 + p * Math.sin(r);
		out[o + 2] = r;
	}

	private function addCurvePosition (p:Number, x1:Number, y1:Number, cx1:Number, cy1:Number, cx2:Number, cy2:Number, x2:Number, y2:Number,
		out:Vector<Number>, o:Int, tangents:Bool) : Void {
		if (p == 0) p = 0.0001;
		var tt:Number = p * p, ttt:Number = tt * p, u:Number = 1 - p, uu:Number = u * u, uuu:Number = uu * u;
		var ut:Number = u * p, ut3:Number = ut * 3, uut3:Number = u * ut3, utt3:Number = ut3 * p;
		var x:Number = x1 * uuu + cx1 * uut3 + cx2 * utt3 + x2 * ttt, y:Number = y1 * uuu + cy1 * uut3 + cy2 * utt3 + y2 * ttt;
		out[o] = x;
		out[o + 1] = y;
		if (tangents) out[o + 2] = Math.atan2(y - (y1 * uu + cy1 * ut * 2 + cy2 * tt), x - (x1 * uu + cx1 * ut * 2 + cx2 * tt));
	}

	public var bones(get, never):Vector<Bone>;
	inline function get_bones () : Vector<Bone> {
		return _bones;
	}

	public var data(get, never):PathConstraintData;
	inline function get_data () : PathConstraintData {
		return _data;
	}

	public function toString () : String {
		return _data.name;
	}
}
