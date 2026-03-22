test:
	nvim --headless -u ./scripts/minimal_init.lua -c "lua MiniTest.run()" -c "qa!"

.PHONY: test
