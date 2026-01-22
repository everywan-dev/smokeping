(function () {
    // Traceroute Integration for SmokePing
    var servers = [];

    function init() {
        var target = getParam('target');
        // Filter out undesired views
        if (!target || target.indexOf('~') !== -1 || target === '_charts') return;

        var insertAfterPanel = null;
        var insertPosition = 'after'; // 'after' (sibling) or 'append' (child)

        // STRATEGY 1: Look for Panels (Standard View with 3h, 30h... graphs)
        var panels = document.querySelectorAll('.panel, .panel-no-border');
        for (var i = 0; i < panels.length; i++) {
            var panel = panels[i];
            var h2 = panel.querySelector('.panel-heading h2, .panel-heading-no-border h2');
            if (h2) {
                var txt = h2.textContent;
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
                    // Stop at first graph (3 Hours)
                    break;
                }
            }
        }

        // STRATEGY 2: Look for Zoom/Detail View (displaymode=n)
        // In this view, there might be no panels, just a big <img> tag.
        if (!insertAfterPanel) {
            // Try to find the main graph image. 
            // Usually mostly alone in a div or table cell.
            var imgs = document.getElementsByTagName('img');
            for (var i = 0; i < imgs.length; i++) {
                var img = imgs[i];
                // SmokePing RRD graphs are served via smokeping.cgi or contain typical dimensions
                // Checking if src contains certain keywords or if it's large
                if (img.src && (img.src.indexOf('smokeping.cgi') !== -1 || img.src.indexOf('RRD_') !== -1)) {
                    // Check if it's the main graph (usually wider than icon)
                    if (img.width > 300) {
                        insertAfterPanel = img;
                        // If we found server name before, good. If not, use generic.
                        if (servers.length === 0) {
                            servers.push({
                                name: target, // Use target name as label
                                endpoint: '/smokeping/traceping.cgi',
                                host: target // In zoom view, we might not know the slave, assume master/target
                            });
                        }
                        break;
                    }
                }
            }
        }

        // Fallback checks
        if (!insertAfterPanel && servers.length === 0) {
            // Should we force insert at bottom?
            // Let's rely on finding *something*.
            return;
        }

        if (servers.length === 0) {
            servers.push({
                name: 'Master',
                endpoint: '/smokeping/traceping.cgi',
                host: 'smokeping-master'
            });
        }

        // Create Traceroute Panel UI
        var idx = 0;
        var s = servers[idx];
        var div = document.createElement('div');
        div.className = 'traceroute-panel';
        div.style.cssText = 'margin:15px auto 25px auto;padding:18px;background:linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);border-radius:8px;border:1px solid #dee2e6;box-shadow:0 2px 4px rgba(0,0,0,0.05);max-width:95%;';

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

        // Injection Logic
        if (insertAfterPanel && insertAfterPanel.parentNode) {
            // Check if we are inserting after a panel or an image inside a container
            // If it's an image in Zoom view, sometimes it's inside a <TD> or <DIV>

            // Try to find the closest block container to insert AFTER
            var container = insertAfterPanel;
            while (container.tagName === 'IMG' || container.tagName === 'A') {
                container = container.parentNode;
            }

            // Insert after the container of the graph
            if (container.parentNode) {
                container.parentNode.insertBefore(div, container.nextSibling);
            } else {
                // Fallback
                insertAfterPanel.parentNode.insertBefore(div, insertAfterPanel.nextSibling);
            }
        }

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
                var m = txt.match(/<pre[^>]*>([\s\S]*?)<\/pre>/i);
                var content = m ? m[1] : txt.replace(/<[^>]+>/g, '');
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
