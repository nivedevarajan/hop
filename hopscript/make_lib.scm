;*=====================================================================*/
;*    serrano/prgm/project/hop/3.0.x/hopscript/make_lib.scm            */
;*    -------------------------------------------------------------    */
;*    Author      :  Manuel Serrano                                    */
;*    Creation    :  Fri Aug  9 14:00:32 2013                          */
;*    Last change :  Wed Dec 17 15:41:34 2014 (serrano)                */
;*    Copyright   :  2013-14 Manuel Serrano                            */
;*    -------------------------------------------------------------    */
;*    THe module used to build the hopscript heap file.                */
;*=====================================================================*/

;*---------------------------------------------------------------------*/
;*    The module                                                       */
;*---------------------------------------------------------------------*/
(module __hopscript_makelib

   (library hop)
   
   (import __hopscript_types
	   __hopscript_property
	   __hopscript_public
	   __hopscript_lib
	   __hopscript_object
	   __hopscript_arguments
	   __hopscript_function
	   __hopscript_service
	   __hopscript_array
	   __hopscript_arraybuffer	   
	   __hopscript_string
	   __hopscript_stringliteral
	   __hopscript_number 
	   __hopscript_math
	   __hopscript_boolean
	   __hopscript_date
	   __hopscript_regexp
	   __hopscript_error
	   __hopscript_json
	   __hopscript_worker
	   __hopscript_websocket)
   
   (eval   (export-all)

           (class JsStringLiteral)
      
           (class JsObject)
	   (class JsGlobalObject)
	   (class JsFunction)
	   (class JsService)
	   (class JsArray)
	   (class JsArguments)
	   (class JsString)
	   (class JsNumber)
	   (class JsRegExp)
	   (class JsBoolean)
	   (class JsDate)
	   (class JsError)
	   
	   (class JsWorker)
	   
	   (class JsWebSocket)
	   (class JsWebSocketClient)
	   (class JsWebSocketServer)
	   
	   (class JsArrayBuffer)
	   (class JsArrayBufferView)
	   (class JsTypedArray)
	   (class JsInt8Array)
	   (class JsUint8Array)
	   (class JsUint8ClampedArray)
	   (class JsInt16Array)
	   (class JsUint16Array)
	   (class JsInt32Array)
	   (class JsUint32Array)
	   (class JsFloat32Array)
	   (class JsFloat64Array)
	   (class JsDataView)
	   
	   (class JsPropertyCache)
	   
	   (class JsValueDescriptor)
	   (class JsAccessorDescriptor)

	   (class MessageEvent)
	   (class WorkerHopThread)
	   (class JsWebSocketEvent)))
