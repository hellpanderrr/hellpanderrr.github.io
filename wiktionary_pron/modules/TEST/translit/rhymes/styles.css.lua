.ts-rhymesBreadcrumbs {
	display: table;
	margin-bottom: 0.5em;
	padding-bottom: 0.2em;
	border-bottom: 1px solid #c8ccd1;
	font-size: 0.92857143em; /* 13 / 14 */
}

.ts-rhymesBreadcrumbs ol {
	margin: 0;
	padding-left: 0;
	list-style: none;
}

.ts-rhymesBreadcrumbs li {
	display: inline-flex;
	align-items: baseline;
	margin: 0;
}

.ts-rhymesBreadcrumbs li + li::before {
	content: "»";
	color: #54595d;
	margin: 0 0.38461538em; /* 5 / 13 */
}

.ts-rhymesBreadcrumbs a {
	white-space: nowrap;
}