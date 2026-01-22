(function () {
    // Traceroute Integration for SmokePing
    // Dynamically injects a panel with traceroute results based on the target
    var servers = [];

    function init() {
        var target = getParam('target');
        // Only run if we are in a detail view (target is present) and not in special views
        if (!target || target.indexOf('~') !== -1 || target === '_charts') return;

        // Detect current hostname
        var hostname = 'smokeping-master';

        // Find existing panels to determine injection point
        var panels = document.querySelectorAll('.panel, .panel-no-border');
        var insertAfterPanel = null;

        // Loop using for loop to allow breaking on first match
        for (var i = 0; i < panels.length; i++) {
            var panel = panels[i];
            var h2 = panel.querySelector('.panel-heading h2, .panel-heading-no-border h2');
            if (h2) {
                var txt = h2.textContent;
                // Look for "Last 3 Hours from HOSTNAME"
                var m = txt.match(/from (.+)/);
                if (m) {
                    var sdt = m[1].trim();
                    if (servers.length === 0) {
                        servers.push({
                            name: sdt,
                            endpoint: '/smokeping/traceping.cgi',
                            host: sdt
                        });
                    }
                    insertAfterPanel = panel;
                    // WARNING: Stop searching after the first graph (which is the 3 Hours one).
                    // If we don't break, it keeps going and selects the last one (360 Days), putting traceroute at the bottom.
                    break;
                }
            }
        }

        // Fallback if no server detected (use defaults)
        if (servers.length === 0) {
            servers.push({
                name: 'Master',
                endpoint: '/smokeping/traceping.cgi',
                host: 'smokeping-master'
            });
            // Try to find any panel to insert after
            if (!insertAfterPanel && panels.length > 0) {
                insertAfterPanel = panels[0];
            }
        }

        if (!insertAfterPanel) return;

        // Create Traceroute Panel
        var idx = 0;
        var s = servers[idx];
        var div = document.createElement('div');
        div.className = 'traceroute-panel';
        div.style.cssText = 'margin:15px 0 25px 0;padding:18px;background:linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);border-radius:8px;border:1px solid #dee2e6;box-shadow:0 2px 4px rgba(0,0,0,0.05);';

        div.innerHTML =
            '<div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:14px;">' +
            '<h4 style="margin:0;font-size:14px;font-weight:600;color:#212529;display:flex;align-items:center;">' +
            '<span style="background:#28a745;width:8px;height:8px;border-radius:50%;margin-right:8px;animation:pulse 2s infinite;"></span>' +
            '🔍 Traceroute - ' + s.name + '</h4>' +
            '<span style="font-size:11px;color:#6c757d;">Target: ' + target + '</span>' +
            '</div>' +
            '<style>@keyframes pulse{0%,100%{opacity:1}50%{opacity:0.5}}</style>' +
            '<pre id="trace-' + idx + '" style="background:#1e1e1e;color:#d4d4d4;padding:16px;border-radius:6px;font-size:11px;line-height:1.6;max-height:280px;overflow:auto;margin:0;font-family:\'Monaco\',\'Menlo\',\'Consolas\',monospace;border:1px solid #333;">⏳ Loading traceroute...</pre>' +
            '<div style="text-align:center;margin-top:14px;">' +
            '<button id="hist-' + idx + '" style="padding:8px 20px;background:linear-gradient(135deg, #6c757d 0%, #5a6268 100%);color:#fff;border:none;border-radius:5px;cursor:pointer;font-size:12px;font-weight:500;transition:all 0.2s ease;box-shadow:0 2px 4px rgba(0,0,0,0.1);">📋 View History</button>' +
            '<button id="refresh-' + idx + '" style="margin-left:10px;padding:8px 20px;background:linear-gradient(135deg, #28a745 0%, #218838 100%);color:#fff;border:none;border-radius:5px;cursor:pointer;font-size:12px;font-weight:500;transition:all 0.2s ease;box-shadow:0 2px 4px rgba(0,0,0,0.1);">🔄 Refresh</button>' +
            '</div>' +
            '<div id="histbox-' + idx + '" style="display:none;margin-top:16px;"></div>';

        insertAfterPanel.parentNode.insertBefore(div, insertAfterPanel.nextSibling);

        loadTrace(idx, s.endpoint, target);
        setupHist(idx, s.endpoint, target, s.name);
        setupRefresh(idx, s.endpoint, target);
    }

    function getParam(name) {
        var url = window.location.href;
        var regex = new RegExp('[?&]' + name + '=([^&#]*)');
        var results = regex.exec(url);
        return results ? decodeURIComponent(results[1]) : null;
    }

    function loadTrace(idx, endpoint, target) {
        var pre = document.getElementById('trace-' + idx);
        if (!pre) return;

        pre.textContent = '⏳ Loading traceroute...';

        var xhr = new XMLHttpRequest();
        xhr.open('GET', endpoint + '?target=' + encodeURIComponent(target));
        xhr.onload = function () {
            if (xhr.status === 200) {
                var txt = xhr.responseText;
                // Basic HTML stripping and extraction
                var m = txt.match(/<pre[^>]*>([\s\S]*?)<\/pre>/i);
                var content = m ? m[1] : txt.replace(/<[^>]+>/g, '');

                // Clean up excessive asterisks lines (limit to 3 consecutive failure lines)
                var lines = content.split('\n');
                var cleanLines = [];
                var asteriskCount = 0;
                for (var i = 0; i < lines.length; i++) {
                    if (lines[i].trim().match(/^\d+\s+\*\s*$/)) {
                        asteriskCount++;
                        if (asteriskCount <= 3) {
                            cleanLines.push(lines[i]);
                        }
                    } else {
                        asteriskCount = 0;
                        cleanLines.push(lines[i]);
                    }
                }
                pre.textContent = cleanLines.join('\n').trim() || 'No data available';
            } else {
                pre.textContent = '❌ Error loading traceroute';
            }
        };
        xhr.onerror = function () { pre.textContent = '❌ Connection error'; };
        xhr.send();
    }

    function setupRefresh(idx, endpoint, target) {
        var btn = document.getElementById('refresh-' + idx);
        if (!btn) return;

        btn.onclick = function () {
            loadTrace(idx, endpoint, target);
        };

        btn.onmouseover = function () {
            this.style.transform = 'translateY(-1px)';
            this.style.boxShadow = '0 4px 8px rgba(0,0,0,0.15)';
        };
        btn.onmouseout = function () {
            this.style.transform = 'translateY(0)';
            this.style.boxShadow = '0 2px 4px rgba(0,0,0,0.1)';
        };
    }

    function setupHist(idx, endpoint, target, serverName) {
        var btn = document.getElementById('hist-' + idx);
        var box = document.getElementById('histbox-' + idx);
        if (!btn || !box) return;

        btn.onclick = function () {
            if (box.style.display === 'none') {
                box.style.display = 'block';
                box.innerHTML = '<p style="color:#6c757d;font-size:12px;text-align:center;padding:20px;">⏳ Loading history...</p>';
                btn.innerHTML = '🔼 Hide History';
                btn.style.background = 'linear-gradient(135deg, #495057 0%, #343a40 100%)';

                var xhr = new XMLHttpRequest();
                xhr.open('GET', endpoint + '?target=' + encodeURIComponent(target) + '&history=1');
                xhr.onload = function () {
                    if (xhr.status === 200) {
                        var html = '<div style="background:#fff;border:1px solid #dee2e6;border-radius:6px;padding:14px;box-shadow:0 1px 3px rgba(0,0,0,0.05);">';
                        html += '<div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:12px;padding-bottom:10px;border-bottom:1px solid #e9ecef;">';
                        html += '<span style="font-size:13px;font-weight:600;color:#212529;">📜 History - ' + serverName + '</span>';
                        html += '</div>';
                        html += '<div id="histcontent-' + idx + '" style="max-height:400px;overflow:auto;">' + xhr.responseText + '</div>';
                        html += '</div>';
                        box.innerHTML = html;
                    } else {
                        box.innerHTML = '<p style="color:#dc3545;font-size:12px;text-align:center;padding:20px;">❌ No history available</p>';
                    }
                };
                xhr.onerror = function () { box.innerHTML = '<p style="color:#dc3545;font-size:12px;text-align:center;">❌ Connection error</p>'; };
                xhr.send();
            } else {
                box.style.display = 'none';
                btn.innerHTML = '📋 View History';
                btn.style.background = 'linear-gradient(135deg, #6c757d 0%, #5a6268 100%)';
            }
        };

        btn.onmouseover = function () {
            this.style.transform = 'translateY(-1px)';
            this.style.boxShadow = '0 4px 8px rgba(0,0,0,0.15)';
        };
        btn.onmouseout = function () {
            this.style.transform = 'translateY(0)';
            this.style.boxShadow = '0 2px 4px rgba(0,0,0,0.1)';
        };
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
