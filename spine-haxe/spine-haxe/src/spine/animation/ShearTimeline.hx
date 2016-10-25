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
import spine.Bone;

class ShearTimeline extends TranslateTimeline {
	public function new (frameCount:Int) {
		super(frameCount);
	}

	override public function apply (skeleton:Skeleton, lastTime:Number, time:Number, firedEvents:Vector<Event>, alpha:Number) : Void {
		var frames:Vector<Number> = this.frames;
		if (time < frames[0]) return; // Time is before first frame.

		var bone:Bone = skeleton.bones[boneIndex];
		if (time >= frames[frames.length - TranslateTimeline.ENTRIES]) { // Time is after last frame.
			bone.shearX += (bone.data.shearX + frames[frames.length + TranslateTimeline.PREV_X] - bone.shearX) * alpha;
			bone.shearY += (bone.data.shearY + frames[frames.length + TranslateTimeline.PREV_Y] - bone.shearY) * alpha;
			return;
		}

		// Interpolate between the previous frame and the current frame.
		var frame:Int = Animation.binarySearch(frames, time, TranslateTimeline.ENTRIES);
		var prevX:Number = frames[frame + TranslateTimeline.PREV_X];
		var prevY:Number = frames[frame + TranslateTimeline.PREV_Y];
		var frameTime:Number = frames[frame];
		var percent:Number = getCurvePercent(int(frame / TranslateTimeline.ENTRIES) - 1, 1 - (time - frameTime) / (frames[frame + TranslateTimeline.PREV_TIME] - frameTime));

		bone.shearX += (bone.data.shearX + (prevX + (frames[frame + TranslateTimeline.X] - prevX) * percent) - bone.shearX) * alpha;
		bone.shearY += (bone.data.shearY + (prevY + (frames[frame + TranslateTimeline.Y] - prevY) * percent) - bone.shearY) * alpha;
	}
}