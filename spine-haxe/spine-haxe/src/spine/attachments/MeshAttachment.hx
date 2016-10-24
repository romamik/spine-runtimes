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

package spine.attachments;

/*dynamic*/ class MeshAttachment extends VertexAttachment {
	public var worldVertices:Vector<Number>;
	public var uvs:Vector<Number>;
	public var regionUVs:Vector<Number>;
	public var triangles:Vector<UInt>;	
	public var r:Number = 1;
	public var g:Number = 1;
	public var b:Number = 1;
	public var a:Number = 1;
	public var hullLength:Int;
	private var _parentMesh:MeshAttachment;
	public var inheritDeform:Bool;

	public var path:String;
	public var rendererObject:Null<Dynamic>;
	public var regionU:Number;
	public var regionV:Number;
	public var regionU2:Number;
	public var regionV2:Number;
	public var regionRotate:Bool;
	public var regionOffsetX:Number; // Pixels stripped from the bottom left, unrotated.
	public var regionOffsetY:Number;
	public var regionWidth:Number; // Unrotated, stripped size.
	public var regionHeight:Number;
	public var regionOriginalWidth:Number; // Unrotated, unstripped size.
	public var regionOriginalHeight:Number;

	// Nonessential.
	public var edges:Vector<Int>;
	public var width:Number;
	public var height:Number;

	public function new (name:String) {
		super(name);
	}

	public function updateUVs () : Void {
		var width:Number = regionU2 - regionU, height:Number = regionV2 - regionV;
		var i:Int, n:Int = regionUVs.length;
		if (uvs == null || uvs.length != n) uvs = new Vector<Number>(n, true);
		if (regionRotate) {
			var i = 0;
			while (i < n) {
				uvs[i] = regionU + regionUVs[int(i + 1)] * width;
				uvs[int(i + 1)] = regionV + height - regionUVs[i] * height;
				i += 2;
			}
		} else {
			var i = 0;
			while (i < n) {
				uvs[i] = regionU + regionUVs[i] * width;
				uvs[int(i + 1)] = regionV + regionUVs[int(i + 1)] * height;
				i += 2;
			}
		}
	}

	public function applyFFD (sourceAttachment:Attachment) : Bool {
		return this == sourceAttachment || (inheritDeform && _parentMesh == sourceAttachment);
	}

	public var parentMesh(get, set):MeshAttachment;
	inline function get_parentMesh () : MeshAttachment {
		return _parentMesh;
	}

	inline function set_parentMesh (parentMesh:MeshAttachment) : MeshAttachment {
		if (parentMesh != null) {
			bones = parentMesh.bones;
			vertices = parentMesh.vertices;
			worldVerticesLength = parentMesh.worldVerticesLength;
			regionUVs = parentMesh.regionUVs;
			triangles = parentMesh.triangles;
			hullLength = parentMesh.hullLength;
			edges = parentMesh.edges;
			width = parentMesh.width;
			height = parentMesh.height;
		}
		return _parentMesh = parentMesh;
	}
}
