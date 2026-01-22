(function($) {
	"use strict";

	var fullHeight = function() {
		$('.js-fullheight').css('height', $(window).height());
		$(window).resize(function(){
			$('.js-fullheight').css('height', $(window).height());
		});
	};
	fullHeight();

	// Toggle sidebar - simple
	$('#sidebarCollapse').on('click', function () {
		$('#sidebar').toggleClass('active');
	});

	// Menús dropdown para smokeping
	$(document).ready(function() {
		$('ul.menu').first().children('li').each(function() {
			var $li = $(this);
			var $sub = $li.children('ul.menu');
			var $link = $li.children('a').first();
			
			if ($sub.length === 0) return;
			
			// Si contiene el item activo, mantener abierto
			var hasActive = $sub.find('.menuactive, .menulinkactive').length > 0 || $li.hasClass('menuactive');
			
			if (hasActive) {
				$sub.show();
				$link.addClass('menu-open');
			} else {
				$sub.hide();
			}
			
			// Añadir flecha
			var arrow = hasActive ? '▼' : '▶';
			$link.append('<span class="menu-arrow" style="float:right;font-size:9px;opacity:0.6;">' + arrow + '</span>');
			
			// Click en el link principal abre/cierra el submenu
			$link.on('click', function(e) {
				e.preventDefault();
				e.stopPropagation();
				
				if ($sub.is(':visible')) {
					$sub.slideUp(150);
					$(this).find('.menu-arrow').text('▶');
					$(this).removeClass('menu-open');
				} else {
					$sub.slideDown(150);
					$(this).find('.menu-arrow').text('▼');
					$(this).addClass('menu-open');
				}
			});
		});
		
		// Los sublinks navegan normalmente
		$('ul.menu ul.menu a').on('click', function(e) {
			e.stopPropagation();
		});
	});

})(jQuery);
