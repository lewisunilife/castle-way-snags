// Mock that rejects snag_id until __hasSnagId is switched on, reproducing
// a project where the column has not been added yet.
(function () {
  var KEY='__mock_server4__';
  var chan=new BroadcastChannel('mocksb4');
  var handlers=[]; window.__hasSnagId=false;
  function read(){try{return JSON.parse(localStorage.getItem(KEY))||{castle_way_snags:{},castle_way_comments:{}};}catch(e){return {castle_way_snags:{},castle_way_comments:{}};}}
  function write(t){localStorage.setItem(KEY,JSON.stringify(t));}
  function fire(tb,ty,rw){handlers.forEach(function(h){if(h.table!==tb)return;if(h.event!=='*'&&h.event!==ty)return;h.cb({eventType:ty,new:rw,old:rw});});}
  chan.onmessage=function(e){fire(e.data.table,e.data.type,e.data.row);};
  function put(tb,k,rw,ty){var t=read();t[tb][k]=rw;write(t);chan.postMessage({table:tb,type:ty,row:rw});fire(tb,ty,rw);return {data:[rw],error:null};}
  function q(tb){return {
    select:function(){var t=read();var p=Promise.resolve({data:Object.keys(t[tb]).map(function(k){return t[tb][k];}),error:null});p.order=function(){return p;};return p;},
    upsert:function(rw){var t=read();rw.updated_at=new Date().toISOString();return Promise.resolve(put(tb,rw.id,rw,t[tb][rw.id]?'UPDATE':'INSERT'));},
    insert:function(rw){
      if ('snag_id' in rw && rw.snag_id !== null && !window.__hasSnagId) {
        return Promise.resolve({data:null,error:{code:'PGRST204',message:"Could not find the 'snag_id' column of 'castle_way_comments' in the schema cache"}});
      }
      var t=read(); if(t[tb][rw.id]) return Promise.resolve({data:null,error:{code:'23505'}});
      rw.created_at=new Date().toISOString(); return Promise.resolve(put(tb,rw.id,rw,'INSERT'));}
  };}
  window.supabase={createClient:function(){return {from:function(t){return q(t);},removeChannel:function(){handlers=[];},
    channel:function(){var ch={on:function(_e,o,cb){handlers.push({table:o.table,event:o.event,cb:cb});return ch;},subscribe:function(cb){setTimeout(function(){cb('SUBSCRIBED');},10);return ch;}};return ch;}};}};
})();
