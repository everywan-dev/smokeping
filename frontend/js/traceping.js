// everyWAN Traceroute - Docker Version
// Works in normal view and Navigator Graph
(function () {
    'use strict';

    // Single server for Docker environment
    var defaultEndpoint = '/smokeping/traceping.cgi';

    function getParam(name) {
        // Smokeping uses ; as separator, not &
        var search = window.location.search.replace(/;/g, '&');
        var params = new URLSearchParams(search);
        return params.get(name);
    }

    function init() {
        var target = getParam('target');
        if (!target || target.indexOf('.') === -1) return;

        var displaymode = getParam('displaymode');

        if (displaymode === 'n') {
            // Navigator Graph view - show traceroute below the graph
            initNavigatorMode(target);
        } else {
            // Normal view - show traceroutes after each "Last 3 Hours"
            initNormalMode(target);
        }
    }

    function initNavigatorMode(target) {
        // Determine server based on the target
        var cleanTarget = target;
        var serverName = 'smokeping-master';

        if (target.indexOf('~') !== -1) {
            var parts = target.split('~');
            cleanTarget = parts[0];
            serverName = parts[1];
        }

        // Find the main graph container
        var content = document.getElementById('content');
        if (!content) return;

        // Create traceroute panel
        var div = document.createElement('div');
        div.className = 'traceroute-panel';
        div.style.cssText = 'margin:20px 0;padding:16px;background:#f8f9fa;border-radius:6px;border:1px solid #dee2e6;';

        div.innerHTML =
            '<div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:12px;">' +
            '<h4 style="margin:0;font-size:13px;font-weight:600;color:#212529;">Traceroute - ' + serverName + '</h4>' +
            '</div>' +
            '<pre id="trace-nav" style="background:#1e1e1e;color:#d4d4d4;padding:14px;border-radius:4px;font-size:11px;line-height:1.5;max-height:220px;overflow:auto;margin:0;font-family:Consolas,Monaco,monospace;">Loading...</pre>' +
            '<div style="text-align:center;margin-top:12px;">' +
            '<button id="hist-nav" style="padding:6px 16px;background:#6c757d;color:#fff;border:none;border-radius:3px;cursor:pointer;font-size:11px;font-weight:500;">View History</button>' +
            '</div>' +
            '<div id="histbox-nav" style="display:none;margin-top:14px;"></div>';

        // Insert at the END of content (below the graph)
        content.appendChild(div);

        // Load traceroute
        loadTrace('nav', defaultEndpoint, cleanTarget);
        setupHist('nav', defaultEndpoint, cleanTarget, serverName);
    }

    function initNormalMode(target) {
        // Dynamically detect server from the graph title
        // Support both production (.panel-heading) and Docker (.panel-heading-no-border) classes
        var servers = [];
        var panels = document.querySelectorAll('div.panel, div.panel-no-border');

        panels.forEach(function (panel) {
            var h2 = panel.querySelector('.panel-heading h2, .panel-heading-no-border h2');
            if (h2 && h2.textContent.indexOf('Last 3 Hours') !== -1) {
                var txt = h2.textContent || '';
                var match = txt.match(/from (.+)/);
                if (match) {
                    var hostname = match[1].trim();
                    servers.push({
                        name: hostname,
                        endpoint: defaultEndpoint,
                        host: hostname
                    });
                }
            }
        });

        if (servers.length === 0) return;

        panels.forEach(function (panel) {
            var h2 = panel.querySelector('.panel-heading h2, .panel-heading-no-border h2');
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
                '<pre id="trace-' + idx + '" style="background:#1e1e1e;color:#d4d4d4;padding:14px;border-radius:4px;font-size:11px;line-height:1.5;max-height:220px;overflow:auto;margin:0;font-family:Consolas,Monaco,monospace;">Loading...</pre>' +
                '<div style="text-align:center;margin-top:12px;">' +
                '<button id="hist-' + idx + '" style="padding:6px 16px;background:#6c757d;color:#fff;border:none;border-radius:3px;cursor:pointer;font-size:11px;font-weight:500;">View History</button>' +
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
        xhr.onload = function () {
            if (xhr.status === 200) {
                var txt = xhr.responseText;
                var m = txt.match(/<pre[^>]*>([\s\S]*?)<\/pre>/i);
                pre.textContent = m ? m[1] : txt.replace(/<[^>]+>/g, '');
            } else {
                pre.textContent = 'Error loading';
            }
        };
        xhr.onerror = function () { pre.textContent = 'Connection error'; };
        xhr.send();
    }

    function setupHist(idx, endpoint, target, serverName) {
        var btn = document.getElementById('hist-' + idx);
        var box = document.getElementById('histbox-' + idx);
        if (!btn || !box) return;

        btn.onclick = function () {
            if (box.style.display === 'none') {
                box.style.display = 'block';
                btn.textContent = 'Hide History';
                btn.style.background = '#495057';
                showHistoryUI(idx, endpoint, target, serverName, box);
            } else {
                box.style.display = 'none';
                btn.textContent = 'View History';
                btn.style.background = '#6c757d';
            }
        };

        btn.onmouseover = function () { this.style.background = this.textContent === 'Hide History' ? '#343a40' : '#5a6268'; };
        btn.onmouseout = function () { this.style.background = this.textContent === 'Hide History' ? '#495057' : '#6c757d'; };
    }

    function showHistoryUI(idx, endpoint, target, serverName, box) {
        var today = new Date().toISOString().split('T')[0];
        var html = '<div style="background:#fff;border:1px solid #dee2e6;border-radius:4px;padding:12px;">';
        html += '<div style="display:flex;flex-wrap:wrap;gap:10px;align-items:center;margin-bottom:12px;padding-bottom:10px;border-bottom:1px solid #e9ecef;">';
        html += '<span style="font-size:12px;font-weight:600;color:#212529;">History - ' + serverName + '</span>';
        html += '<div style="margin-left:auto;display:flex;gap:6px;align-items:center;">';
        html += '<input type="date" id="datefilter-' + idx + '" value="' + today + '" style="padding:4px 8px;border:1px solid #ced4da;border-radius:3px;font-size:11px;">';
        html += '<select id="hourfilter-' + idx + '" style="padding:4px 8px;border:1px solid #ced4da;border-radius:3px;font-size:11px;">';
        html += '<option value="">All hours</option>';
        for (var h = 0; h < 24; h++) {
            var hStr = h.toString().padStart(2, '0');
            html += '<option value="' + h + '">' + hStr + ':00 - ' + hStr + ':59</option>';
        }
        html += '</select>';
        html += '<button id="searchhist-' + idx + '" style="padding:4px 12px;background:#0d6efd;color:#fff;border:none;border-radius:3px;font-size:11px;cursor:pointer;">Search</button>';
        html += '</div></div>';
        html += '<div id="histcontent-' + idx + '" style="max-height:350px;overflow:auto;"><p style="color:#6c757d;font-size:12px;text-align:center;">Loading...</p></div>';
        html += '</div>';
        box.innerHTML = html;

        loadHistory(idx, endpoint, target, '', '');

        var searchBtn = document.getElementById('searchhist-' + idx);
        if (searchBtn) {
            searchBtn.onclick = function () {
                var dateVal = document.getElementById('datefilter-' + idx).value;
                var hourVal = document.getElementById('hourfilter-' + idx).value;
                loadHistory(idx, endpoint, target, dateVal, hourVal);
            };
        }
    }

    function loadHistory(idx, endpoint, target, dateFilter, hourFilter) {
        var content = document.getElementById('histcontent-' + idx);
        if (!content) return;

        content.innerHTML = '<p style="color:#6c757d;font-size:12px;text-align:center;">Loading...</p>';

        var url = endpoint + '?target=' + encodeURIComponent(target) + '&history=1&limit=30';
        if (dateFilter) url += '&date=' + encodeURIComponent(dateFilter);
        if (hourFilter) url += '&hour=' + encodeURIComponent(hourFilter);

        var xhr = new XMLHttpRequest();
        xhr.open('GET', url);
        xhr.onload = function () {
            if (xhr.status === 200) {
                content.innerHTML = xhr.responseText;
            } else {
                content.innerHTML = '<p style="color:#dc3545;font-size:12px;text-align:center;">Error loading history</p>';
            }
        };
        xhr.onerror = function () {
            content.innerHTML = '<p style="color:#dc3545;font-size:12px;text-align:center;">Connection error</p>';
        };
        xhr.send();
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
