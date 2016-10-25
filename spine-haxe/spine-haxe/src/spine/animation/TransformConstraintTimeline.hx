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

package spine.animation;
import spine.Event;
import spine.Skeleton;
import spine.TransformConstraint;

class TransformConstraintTimeline extends CurveTimeline {
    static public inline var ENTRIES:Int = 5;
	 @:allow(spine) static inline var PREV_TIME:Int = -5; @:allow(spine) static inline var PREV_ROTATE:Int = -4; @:allow(spine) static inline var PREV_TRANSLATE:Int = -3; @:allow(spine) static inline var PREV_SCALE:Int = -2; @:allow(spine) static inline var PREV_SHEAR:Int = -1;
	 @:allow(spine) static inline var ROTATE:Int = 1; @:allow(spine) static inline var TRANSLATE:Int = 2; @:allow(spine) static inline var SCALE:Int = 3; @:allow(spine) static inline var SHEAR:Int = 4;

	public var transformConstraintIndex:Int = Default.int;
	public var frames:Vector<Number>; // time, rotate mix, translate mix, scale mix, shear mix, ...

	public function new (frameCount:Int) {
		super(frameCount);
		frames = new Vector<Number>(frameCount * ENTRIES, true);
	}

	/** Sets the time and mixes of the specified keyframe. */
	public function setFrame (frameIndex:Int, time:Number, rotateMix:Number, translateMix:Number, scaleMix:Number, shearMix:Number) : Void {
		frameIndex *= ENTRIES;
		frames[frameIndex] = time;
		frames[frameIndex + ROTATE] = rotateMix;
		frames[frameIndex + TRANSLATE] = translateMix;
		frames[frameIndex + SCALE] = scaleMix;
		frames[frameIndex + SHEAR] = shearMix;
	}

	override public function apply (skeleton:Skeleton, lastTime:Number, time:Number, firedEvents:Vector<Event>, alpha:Number) : Void {
		if (time < frames[0]) return; // Time is before first frame.

		var constraint:TransformConstraint = skeleton.transformConstraints[transformConstraintIndex];

		if (time >= frames[frames.length - ENTRIES]) { // Time is after last frame.
			var i:Int = frames.length;
			constraint.rotateMix += (frames[i + PREV_ROTATE] - constraint.rotateMix) * alpha;
			constraint.translateMix += (frames[i + PREV_TRANSLATE] - constraint.translateMix) * alpha;
			constraint.scaleMix += (frames[i + PREV_SCALE] - constraint.scaleMix) * alpha;
			constraint.shearMix += (frames[i + PREV_SHEAR] - constraint.shearMix) * alpha;
			return;
		}

		// Interpolate between the previous frame and the current frame.
		var frame:Int = Animation.binarySearch(frames, time, ENTRIES);
		var frameTime:Number = frames[frame];
		var percent:Number = getCurvePercent(int(frame / ENTRIES) - 1, 1 - (time - frameTime) / (frames[frame + PREV_TIME] - frameTime));

		var rotate:Number = frames[frame + PREV_ROTATE];
		var translate:Number = frames[frame + PREV_TRANSLATE];
		var scale:Number = frames[frame + PREV_SCALE];
		var shear:Number = frames[frame + PREV_SHEAR];
		constraint.rotateMix += (rotate + (frames[frame + ROTATE] - rotate) * percent - constraint.rotateMix) * alpha;
		constraint.translateMix += (translate + (frames[frame + TRANSLATE] - translate) * percent - constraint.translateMix)
			* alpha;
		constraint.scaleMix += (scale + (frames[frame + SCALE] - scale) * percent - constraint.scaleMix) * alpha;
		constraint.shearMix += (shear + (frames[frame + SHEAR] - shear) * percent - constraint.shearMix) * alpha;
	}
}
