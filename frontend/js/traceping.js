// everyWAN Traceroute - Enterprise Style (Docker Version)
(function() {
    'use strict';
    
    function getParam(name) {
        var params = new URLSearchParams(window.location.search);
        return params.get(name);
    }
    
    function init() {
        var target = getParam('target');
        if (!target || target.indexOf('.') === -1) return;
        
        // Detectar servidor dinámicamente desde el título del gráfico
        var servers = [];
        var panels = document.querySelectorAll('div.panel');
        panels.forEach(function(panel) {
            var h2 = panel.querySelector('.panel-heading h2');
            if (h2 && h2.textContent.indexOf('Last 3 Hours') !== -1) {
                var txt = h2.textContent || '';
                var match = txt.match(/from (.+)/);
                if (match) {
                    var hostname = match[1].trim();
                    servers.push({
                        name: hostname,
                        endpoint: '/smokeping/traceping.cgi',
                        host: hostname
                    });
                }
            }
        });
        
        if (servers.length === 0) return;
        
        panels.forEach(function(panel) {
            var h2 = panel.querySelector('.panel-heading h2');
            if (!h2) return;
            var txt = h2.textContent || '';
            if (txt.indexOf('Last 3 Hours') === -1) return;
            
            var idx = -1;
            for (var i = 0; i < servers.length; i++) {
                if (txt.indexOf(servers[i].host) !== -1) { idx = i; break; }
            }
            if (idx === -1) return;
            
            var s = servers[idx];
            var div = document.createElement('div');
            div.className = 'traceroute-panel';
            div.style.cssText = 'margin:10px 0 20px 0;padding:16px;background:#f8f9fa;border-radius:6px;border:1px solid #dee2e6;';
            
            div.innerHTML = 
                '<div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:12px;">' +
                    '<h4 style="margin:0;font-size:13px;font-weight:600;color:#212529;">Traceroute - ' + s.name + '</h4>' +
                '</div>' +
                '<pre id="trace-' + idx + '" style="background:#1e1e1e;color:#d4d4d4;padding:14px;border-radius:4px;font-size:11px;line-height:1.5;max-height:220px;overflow:auto;margin:0;font-family:Consolas,Monaco,monospace;">Cargando...</pre>' +
                '<div style="text-align:center;margin-top:12px;">' +
                    '<button id="hist-' + idx + '" style="padding:6px 16px;background:#6c757d;color:#fff;border:none;border-radius:3px;cursor:pointer;font-size:11px;font-weight:500;">Ver Historial</button>' +
                '</div>' +
                '<div id="histbox-' + idx + '" style="display:none;margin-top:14px;"></div>';
            
            panel.parentNode.insertBefore(div, panel.nextSibling);
            
            loadTrace(idx, s.endpoint, target);
            setupHist(idx, s.endpoint, target, s.name);
        });
    }
    
    function loadTrace(idx, endpoint, target) {
        var pre = document.getElementById('trace-' + idx);
        if (!pre) return;
        
        var xhr = new XMLHttpRequest();
        xhr.open('GET', endpoint + '?target=' + encodeURIComponent(target));
        xhr.onload = function() {
            if (xhr.status === 200) {
                var txt = xhr.responseText;
                var m = txt.match(/<pre[^>]*>([\s\S]*?)<\/pre>/i);
                pre.textContent = m ? m[1] : txt.replace(/<[^>]+>/g, '');
            } else {
                pre.textContent = 'Error al cargar';
            }
        };
        xhr.onerror = function() { pre.textContent = 'Error de conexión'; };
        xhr.send();
    }
    
    function setupHist(idx, endpoint, target, serverName) {
        var btn = document.getElementById('hist-' + idx);
        var box = document.getElementById('histbox-' + idx);
        if (!btn || !box) return;
        
        btn.onclick = function() {
            if (box.style.display === 'none') {
                box.style.display = 'block';
                box.innerHTML = '<p style="color:#6c757d;font-size:12px;text-align:center;">Cargando historial...</p>';
                btn.textContent = 'Ocultar Historial';
                btn.style.background = '#495057';
                
                var xhr = new XMLHttpRequest();
                xhr.open('GET', endpoint + '?target=' + encodeURIComponent(target) + '&history=1');
                xhr.onload = function() {
                    if (xhr.status === 200) {
                        var html = '<div style="background:#fff;border:1px solid #dee2e6;border-radius:4px;padding:12px;">';
                        html += '<div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:10px;padding-bottom:8px;border-bottom:1px solid #e9ecef;">';
                        html += '<span style="font-size:12px;font-weight:600;color:#212529;">Historial - ' + serverName + '</span>';
                        html += '<input type="date" id="datefilter-' + idx + '" style="padding:4px 8px;border:1px solid #ced4da;border-radius:3px;font-size:11px;" placeholder="Filtrar por fecha">';
                        html += '</div>';
                        html += '<div id="histcontent-' + idx + '" style="max-height:350px;overflow:auto;">' + xhr.responseText + '</div>';
                        html += '</div>';
                        box.innerHTML = html;
                    } else {
                        box.innerHTML = '<p style="color:#dc3545;font-size:12px;text-align:center;">Sin historial disponible</p>';
                    }
                };
                xhr.onerror = function() { box.innerHTML = '<p style="color:#dc3545;font-size:12px;text-align:center;">Error</p>'; };
                xhr.send();
            } else {
                box.style.display = 'none';
                btn.textContent = 'Ver Historial';
                btn.style.background = '#6c757d';
            }
        };
        
        btn.onmouseover = function() { this.style.background = this.textContent === 'Ocultar Historial' ? '#343a40' : '#5a6268'; };
        btn.onmouseout = function() { this.style.background = this.textContent === 'Ocultar Historial' ? '#495057' : '#6c757d'; };
    }
    
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
