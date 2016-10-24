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

package spine.flash;
import haxe.ds.WeakMap;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.BlendMode;
import flash.display.Sprite;
import flash.events.Event;
import flash.geom.ColorTransform;
import flash.geom.Point;
import flash.geom.Rectangle;

import spine.Bone;
import spine.Skeleton;
import spine.SkeletonData;
import spine.Slot;
import spine.atlas.AtlasRegion;
import spine.attachments.RegionAttachment;

class SkeletonSprite extends Sprite {
	static private var blendModes:Vector<String> = cast Vector.ofArray([
		BlendMode.NORMAL, BlendMode.ADD, BlendMode.MULTIPLY, BlendMode.SCREEN]);

	private var _skeleton:Skeleton;
	public var timeScale:Number = 1;
	private var lastTime:Number = 0;
	private var wrappers:Map<RegionAttachment, Sprite> = new Map();

	public function new (skeletonData:SkeletonData) {
		super();

		Bone.yDown = true;

		_skeleton = new Skeleton(skeletonData);
		_skeleton.updateWorldTransform();

		addEventListener(Event.ENTER_FRAME, enterFrame);
	}

	private function enterFrame (event:Event) : Void {
		var time:Number = haxe.Timer.stamp();
		advanceTime(time - lastTime);
		lastTime = time;
	}

	public function advanceTime (delta:Number) : Void {
		_skeleton.update(delta * timeScale);

		removeChildren();
		var drawOrder:Vector<Slot> = skeleton.drawOrder;
		for (i in 0...drawOrder.length) {
			var slot:Slot = drawOrder[i];
			var regionAttachment:RegionAttachment = Std.instance(slot.attachment, RegionAttachment);
			if (regionAttachment == null) continue;

			var wrapper:Sprite = wrappers[regionAttachment];
			if (wrapper == null) {
				var region:AtlasRegion = AtlasRegion.safeCast(regionAttachment.rendererObject);
				var regionHeight:Number = region.rotate ? region.width : region.height;
				var regionData:BitmapData =  Std.instance(region.rendererObject, BitmapData);
				if (regionData == null) {
					var bitmapData:BitmapData =  Std.instance(region.page.rendererObject, BitmapData);
					var regionWidth:Number = region.rotate ? region.height : region.width;
					regionData = new BitmapData(int(regionWidth), int(regionHeight));
					regionData.copyPixels(bitmapData, new Rectangle(region.x, region.y, regionWidth, regionHeight), new Point());
					region.rendererObject = regionData;
				}

				var bitmap:Bitmap = new Bitmap(regionData);
				bitmap.smoothing = true;

				// Rotate and scale using default registration point (top left corner, y-down, CW) instead of image center.
				bitmap.rotation = -regionAttachment.rotation;
				bitmap.scaleX = regionAttachment.scaleX * (regionAttachment.width / region.width);
				bitmap.scaleY = regionAttachment.scaleY * (regionAttachment.height / region.height);

				// Position using attachment translation, shifted as if scale and rotation were at image center.
				var radians:Number = -regionAttachment.rotation * Math.PI / 180;
				var cos:Number = Math.cos(radians);
				var sin:Number = Math.sin(radians);
				var shiftX:Number = -regionAttachment.width / 2 * regionAttachment.scaleX;
				var shiftY:Number = -regionAttachment.height / 2 * regionAttachment.scaleY;
				if (region.rotate) {
					bitmap.rotation += 90;
					shiftX += regionHeight * (regionAttachment.width / region.width);
				}
				bitmap.x = regionAttachment.x + shiftX * cos - shiftY * sin;
				bitmap.y = -regionAttachment.y + shiftX * sin + shiftY * cos;

				// Use bone as registration point.
				wrapper = new Sprite();
				wrapper.transform.colorTransform = new ColorTransform();
				wrapper.addChild(bitmap);
				wrappers[regionAttachment] = wrapper;
			}

			wrapper.blendMode = cast blendModes[slot.data.blendMode.ordinal];

			var colorTransform:ColorTransform = wrapper.transform.colorTransform;
			colorTransform.redMultiplier = skeleton.r * slot.r * regionAttachment.r;
			colorTransform.greenMultiplier = skeleton.g * slot.g * regionAttachment.g;
			colorTransform.blueMultiplier = skeleton.b * slot.b * regionAttachment.b;
			colorTransform.alphaMultiplier = skeleton.a * slot.a * regionAttachment.a;
			wrapper.transform.colorTransform = colorTransform;

			var bone:Bone = slot.bone;
			var flipX:Int = skeleton.flipX ? -1 : 1;
			var flipY:Int = skeleton.flipY ? -1 : 1;

			wrapper.x = bone.worldX;
			wrapper.y = bone.worldY;
			wrapper.rotation = bone.worldRotationX * flipX * flipY;
			wrapper.scaleX = bone.worldScaleX * flipX;
			wrapper.scaleY = bone.worldScaleY * flipY;
			addChild(wrapper);
		}
	}

	public var skeleton(get, never):Skeleton;
	inline function get_skeleton () : Skeleton {
		return _skeleton;
	}
}
