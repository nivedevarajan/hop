/*=====================================================================*/
/*    serrano/prgm/project/hop/3.0.x/examples/wsserver/wsserver.js     */
/*    -------------------------------------------------------------    */
/*    Author      :  Manuel Serrano                                    */
/*    Creation    :  Wed May 14 17:02:10 2014                          */
/*    Last change :  Fri Jul  4 17:35:57 2014 (serrano)                */
/*    Copyright   :  2014 Manuel Serrano                               */
/*    -------------------------------------------------------------    */
/*    WebSocket server example                                         */
/*    -------------------------------------------------------------    */
/*    run: hop -p 9999 -v -g wsserver.js                               */
/*=====================================================================*/

var wss = new WebSocketServer( "wss" );

wss.onconnection = function( event ) {
   var ws = event.value;

   console.log( "connection established:", ws.socket );

   ws.onmessage = function( event ) {
      console.log('received [%s]', event.value);
   };
   ws.send('something');
};