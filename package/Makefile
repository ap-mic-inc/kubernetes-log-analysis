build_python_package:
	pip install --upgrade setuptools wheel
	python setup.py sdist bdist_wheel
	pip install  ./dist/kubernetes_log_analysis-0.1.0-py3-none-any.whl
	@echo "Build and install the Python package successfully."
	@echo "You can now use the kubernetes_log_analysis module in your Python scripts."

clean:
	rm -rf build dist *.egg-info
	@echo "Cleaned up build artifacts."
	@echo "You can now rebuild the package if needed."
	@echo "To uninstall the package, run: pip uninstall kubernetes-log-analysis"

uninstall:
	pip uninstall -y kubernetes-log-analysis
	@echo "Uninstalled the kubernetes-log-analysis package."
	@echo "You can now rebuild the package if needed."
	@echo "To install the package, run: pip install ./dist/kubernetes_log_analysis-0.1.0-py3-none-any.whl"

install-package:
	pip install ./dist/kubernetes_log_analysis-0.1.0-py3-none-any.whl
	@echo "Installed the kubernetes-log-analysis package."
	@echo "You can now use the kubernetes_log_analysis module in your Python scripts."