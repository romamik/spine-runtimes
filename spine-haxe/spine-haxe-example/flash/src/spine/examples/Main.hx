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

package spine.examples;

import flash.Lib;
import flash.display.BitmapData;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.utils.ByteArray;
import spine.*;
import spine.animation.AnimationStateData;
import spine.atlas.Atlas;
import spine.attachments.AtlasAttachmentLoader;
import spine.flash.FlashTextureLoader;
import spine.flash.SkeletonAnimation;

@:file("/spineboy.atlas") 
class SpineboyAtlas extends ByteArray { }

@:bitmap("/spineboy.png") 
class SpineboyAtlasTexture extends BitmapData { }

@:file("/spineboy.json") 
class SpineboyJson extends ByteArray { }

class Main {

	static var skeleton:SkeletonAnimation;

	static function main () {
		var stage = Lib.current.stage;
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;
		stage.stageWidth = 800;
		stage.stageHeight = 600;
		stage.frameRate = 60;
		stage.color = 0xDDDDDD;
		
		var atlas:Atlas = new Atlas(new SpineboyAtlas(), new FlashTextureLoader(new SpineboyAtlasTexture(0, 0)));
		var json:SkeletonJson = new SkeletonJson(new AtlasAttachmentLoader(atlas));
		json.scale = 0.6;
		var skeletonData:SkeletonData = json.readSkeletonData(new SpineboyJson());

		var stateData:AnimationStateData = new AnimationStateData(skeletonData);
		stateData.setMixByName("walk", "jump", 0.2);
		stateData.setMixByName("jump", "run", 0.4);
		stateData.setMixByName("jump", "jump", 0.2);

		skeleton = new SkeletonAnimation(skeletonData, stateData);
		skeleton.x = 400;
		skeleton.y = 560;
		
		skeleton.state.onStart.add(function (trackIndex:Int, _) : Void {
			trace(trackIndex + " fuu start: " + skeleton.state.getCurrent(trackIndex));
		});
		skeleton.state.onEnd.add(function (trackIndex:Int, _) : Void {
			trace(trackIndex + " end: " + skeleton.state.getCurrent(trackIndex));
		});
		skeleton.state.onComplete.add(function (trackIndex:Int, count:Int) : Void {
			trace(trackIndex + " complete: " + skeleton.state.getCurrent(trackIndex) + ", " + count);
		});
		skeleton.state.onEvent.add(function (trackIndex:Int, event:Event) : Void {
			trace(trackIndex + " event: " + skeleton.state.getCurrent(trackIndex) + ", "
				+ event.data.name + ": " + event.intValue + ", " + event.floatValue + ", " + event.stringValue);
		});
		
		if (false) {
			skeleton.state.setAnimationByName(0, "test", true);
		} else {
			skeleton.state.setAnimationByName(0, "walk", true);
			skeleton.state.addAnimationByName(0, "jump", false, 3);
			skeleton.state.addAnimationByName(0, "run", true, 0);
		}

		Lib.current.addChild(skeleton);
	}
}
