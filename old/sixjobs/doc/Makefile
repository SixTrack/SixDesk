
all: sixdesk_env.pdf sixdesk_env.html


sixdesk_env.pdf: sixdesk_env.tex
	pdflatex sixdesk_env.tex
	pdflatex sixdesk_env.tex
	pdflatex sixdesk_env.tex

sixdesk_env.html: sixdesk_env.tex sixdesk_env_html.tex
	htlatex sixdesk_env_html.tex
