// Mock that rejects snag_id until __hasSnagId is switched on, reproducing
// a project where the column has not been added yet. select() honours
// order, gt and range like PostgREST, and logs each read to __mockCalls.
(function () {
  var KEY='__mock_server4__';
  var chan=new BroadcastChannel('mocksb4');
  var handlers=[]; window.__hasSnagId=false; window.__mockCalls=[];
  function read(){try{return JSON.parse(localStorage.getItem(KEY))||{castle_way_snags:{},castle_way_comments:{}};}catch(e){return {castle_way_snags:{},castle_way_comments:{}};}}
  function write(t){localStorage.setItem(KEY,JSON.stringify(t));}
  function fire(tb,ty,rw){handlers.forEach(function(h){if(h.table!==tb)return;if(h.event!=='*'&&h.event!==ty)return;h.cb({eventType:ty,new:rw,old:rw});});}
  chan.onmessage=function(e){fire(e.data.table,e.data.type,e.data.row);};
  function put(tb,k,rw,ty){var t=read();t[tb][k]=rw;write(t);chan.postMessage({table:tb,type:ty,row:rw});fire(tb,ty,rw);return {data:[rw],error:null};}
  function q(tb){return {
    select:function(){
      var t=read(); var rows=Object.keys(t[tb]).map(function(k){return t[tb][k];});
      var st={gt:[],order:[],range:null};
      var b={
        gt:function(c,v){st.gt.push([c,v]);return b;},
        order:function(c,o){st.order.push([c,!(o&&o.ascending===false)]);return b;},
        range:function(a,z){st.range=[a,z];return b;},
        then:function(ok,ko){
          var out=rows.filter(function(r){return st.gt.every(function(f){return String(r[f[0]]==null?'':r[f[0]])>f[1];});});
          if(st.order.length){out.sort(function(x,y){for(var i=0;i<st.order.length;i++){var c=st.order[i][0],asc=st.order[i][1];var a=String(x[c]==null?'':x[c]),bb=String(y[c]==null?'':y[c]);if(a!==bb)return (a<bb?-1:1)*(asc?1:-1);}return 0;});}
          window.__mockCalls.push({table:tb,gt:st.gt.map(function(f){return f[0];}),range:st.range,total:out.length});
          if(st.range){out=out.slice(st.range[0],st.range[1]+1);}
          return Promise.resolve({data:out,error:null}).then(ok,ko);
        }
      };
      return b;
    },
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
