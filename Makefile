create_doc:
	swift package --allow-writing-to-directory ./docs generate-documentation --target UI --disable-indexing --output-path ./docs --transform-for-static-hosting --hosting-base-path swift-architecture-template-ui
