package com.bourre.ioc.control
{
	/*
	 * Copyright the original author or authors.
	 * 
	 * Licensed under the MOZILLA PUBLIC LICENSE, Version 1.1 (the "License");
	 * you may not use this file except in compliance with the License.
	 * You may obtain a copy of the License at
	 * 
	 *      http://www.mozilla.org/MPL/MPL-1.1.html
	 * 
	 * Unless required by applicable law or agreed to in writing, software
	 * distributed under the License is distributed on an "AS IS" BASIS,
	 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	 * See the License for the specific language governing permissions and
	 * limitations under the License.
	 */

	/**
	 * @author Francis Bourre
	 * @version 1.0
	 */

	public class BuildString
		implements IBuilder
	{
		import com.bourre.log.*;

		public function build ( type : String = null, 
								args : Array = null, 
								factory : String = null, 
								singleton : String = null, 
								channel : String = null		) : *
		{
			var value : String = "";
			if ( args != null && args.length > 0 ) value = ( args[0] ).toString();
			if ( value.length <= 0 ) PixlibDebug.WARN( this + ".build(" + value + ") returns empty String." );
			return value;
		}

		public function toString() : String 
		{
			return PixlibStringifier.stringify( this );
		}
	}
}