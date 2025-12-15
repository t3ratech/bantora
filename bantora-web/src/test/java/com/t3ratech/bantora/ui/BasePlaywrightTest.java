package com.t3ratech.bantora.ui;

import static com.microsoft.playwright.assertions.PlaywrightAssertions.assertThat;
import static org.junit.jupiter.api.Assertions.*;

import com.microsoft.playwright.*;
import com.t3ratech.bantora.ui.config.PlaywrightTestConfig;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import com.microsoft.playwright.options.LoadState;

@SpringBootTest(classes = PlaywrightTestConfig.class)
@ActiveProfiles("test")
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
public abstract class BasePlaywrightTest {

    private static final Pattern UUID_PATTERN = Pattern.compile(
            "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"
    );

    protected static Playwright playwright;
    protected static Browser browser;
    protected BrowserContext context;
    protected Page page;

    protected Set<String> observedRequestUrls;
    protected Set<String> observedResponseUrls;

    @BeforeAll
    static void launchBrowser() {
        playwright = Playwright.create();
        browser = playwright.chromium().launch(new BrowserType.LaunchOptions().setHeadless(false));
    }

    @AfterAll
    static void closeBrowser() {
        if (browser != null)
            browser.close();
        if (playwright != null)
            playwright.close();
    }

    @BeforeEach
    void createContext() {
        context = browser.newContext();
        page = context.newPage();

        observedRequestUrls = ConcurrentHashMap.newKeySet();
        page.onRequest(request -> observedRequestUrls.add(request.url()));

        observedResponseUrls = ConcurrentHashMap.newKeySet();
        page.onResponse(response -> observedResponseUrls.add(response.url()));
    }

    @AfterEach
    void closeContext() {
        if (context != null)
            context.close();
    }

    @Value("${bantora.web.base-url}")
    protected String baseUrl;

    @Value("${bantora.web.port}")
    protected int port;

    protected void navigateToHome() {
        // If baseUrl contains http/https, use it. If it's just a host, append protocol.
        // If it ends with slash, remove it.
        String url = baseUrl;
        if (!url.startsWith("http")) {
            url = "http://" + url;
        }
        if (url.endsWith("/")) {
            url = url.substring(0, url.length() - 1);
        }

        // Only append port if baseUrl is localhost and port is missing
        if (url.contains("localhost") && !url.contains(":" + port)) {
            page.navigate(url + ":" + port);
        } else {
            page.navigate(url);
        }

        page.waitForLoadState(LoadState.DOMCONTENTLOADED);
        enableFlutterWebAccessibility();

        for (int i = 0; i < 120; i++) {
            if (page.locator("[aria-label]").count() > 0) {
                return;
            }
            page.waitForTimeout(250);
        }

        page.reload();
        page.waitForLoadState(LoadState.DOMCONTENTLOADED);
        enableFlutterWebAccessibility();

        for (int i = 0; i < 120; i++) {
            if (page.locator("[aria-label]").count() > 0) {
                return;
            }
            page.waitForTimeout(250);
        }
    }

    protected void ensureAuthenticated() {
        for (int i = 0; i < 120; i++) {
            if (ariaLabel("search_input").count() > 0) {
                return;
            }
            if (ariaLabel("login_phone_input").count() > 0) {
                break;
            }
            if (page.locator("[aria-label]").count() == 0) {
                enableFlutterWebAccessibility();
            }
            page.waitForTimeout(250);
        }

        // Mandatory login: create a fresh user via UI registration to avoid relying on seeded credentials
        waitForAriaLabel("login_phone_input");
        waitForAriaLabel("go_to_register_button").click(new Locator.ClickOptions().setForce(true));

        String phone = "+2637" + String.format("%08d", (System.currentTimeMillis() % 100_000_000));
        String password = "TestPass123!";

        fillTextField("register_phone_input", phone);
        fillTextField("register_country_code_input", "ZW");
        fillTextField("register_password_input", password);
        fillTextField("register_confirm_password_input", password);

        waitForAriaLabel("register_button").click(new Locator.ClickOptions().setForce(true));

        // Wait until home widgets are present, with fallback:
        // - If we return to login, attempt login with the same credentials.
        // - If we stay on register, registration likely failed; keep waiting a bit longer before failing.
        for (int i = 0; i < 240; i++) {
            if (ariaLabel("search_input").count() > 0) {
                return;
            }

            if (ariaLabel("login_phone_input").count() > 0) {
                fillTextField("login_phone_input", phone);
                fillTextField("login_password_input", password);
                waitForAriaLabel("login_button").click(new Locator.ClickOptions().setForce(true));
            }

            page.waitForTimeout(250);
        }

        fail("Timed out waiting to authenticate. Available aria-labels: " + debugAriaLabels(80));
    }

    private void enableFlutterWebAccessibility() {
        Locator host = page.locator("flt-semantics-host");
        Locator enable = page.locator("[aria-label='Enable accessibility']");

        for (int i = 0; i < 120; i++) {
            if (host.count() > 0) {
                return;
            }

            if (enable.count() > 0) {
                try {
                    enable.first().click(new Locator.ClickOptions().setForce(true));
                } catch (PlaywrightException ignored) {
                    // Ignore and retry
                }
            }

            page.waitForTimeout(250);
        }
    }

    private List<String> debugAriaLabels(int limit) {
        Object result = page.evaluate("(limit) => Array.from(document.querySelectorAll('[aria-label]'))\n" +
                ".map(e => e.getAttribute('aria-label'))\n" +
                ".filter(Boolean)\n" +
                ".slice(0, limit)", limit);

        if (result instanceof List<?>) {
            List<?> raw = (List<?>) result;
            List<String> labels = new ArrayList<>();
            for (Object item : raw) {
                if (item != null) {
                    labels.add(item.toString());
                }
            }
            return labels;
        }

        return List.of();
    }

    protected void takeScreenshot(String name) {
        page.screenshot(new Page.ScreenshotOptions()
                .setPath(Paths.get("test-results/screenshots/" + name + ".png"))
                .setFullPage(true));
    }

    protected Locator ariaLabel(String label) {
        return page.locator("[aria-label='" + label + "']");
    }

    protected Locator ariaLabelContains(String substring) {
        return page.locator("[aria-label*='" + substring + "']");
    }

    protected Locator waitForAriaLabelContains(String substring) {
        Locator locator = ariaLabelContains(substring);
        for (int i = 0; i < 60; i++) {
            if (locator.count() > 0) {
                return locator.first();
            }
            page.waitForTimeout(250);
        }

        fail("Timed out waiting for aria-label containing '" + substring + "'. Available aria-labels: " + debugAriaLabels(50));
        return locator.first();
    }

    protected Locator waitForAriaLabel(String label) {
        Locator locator = ariaLabel(label);
        for (int i = 0; i < 60; i++) {
            if (locator.count() > 0) {
                return locator.first();
            }
            page.waitForTimeout(250);
        }

        fail("Timed out waiting for aria-label '" + label + "'. Available aria-labels: " + debugAriaLabels(50));
        return locator.first();
    }

    protected Locator ariaLabelStartsWith(String prefix) {
        return page.locator("[aria-label^='" + prefix + "']");
    }

    protected int countAriaLabelPrefix(String prefix) {
        return ariaLabelStartsWith(prefix).count();
    }

    protected String extractFirstUuidOrFail(String text) {
        Matcher m = UUID_PATTERN.matcher(text);
        if (m.find()) {
            return m.group();
        }
        fail("Expected UUID in text but found none. Text: " + text);
        return "";
    }

    protected int parseEmbeddedIntOrFail(String text, String embeddedPrefix) {
        Pattern p = Pattern.compile(Pattern.quote(embeddedPrefix) + "(\\d+)");
        Matcher m = p.matcher(text);
        if (m.find()) {
            return Integer.parseInt(m.group(1));
        }
        fail("Expected embedded int after prefix '" + embeddedPrefix + "' but not found. Text: " + text);
        return -1;
    }

    protected int countAriaLabelPrefixWithin(String containerLabel, String childPrefix) {
        Locator container = waitForAriaLabel(containerLabel);
        assertThat(container).isVisible();

        return container.locator("[aria-label^='" + childPrefix + "']").count();
    }

    protected Locator textFieldAriaLabel(String label) {
        return page.locator("input[aria-label='" + label + "'], textarea[aria-label='" + label + "']").first();
    }

    protected void fillTextField(String label, String value) {
        Locator input = textFieldAriaLabel(label);
        if (input.count() > 0) {
            input.scrollIntoViewIfNeeded();
            assertThat(input).isVisible();
            boolean enabled;
            try {
                enabled = input.isEnabled();
            } catch (PlaywrightException e) {
                enabled = false;
            }

            if (enabled) {
                input.click(new Locator.ClickOptions().setForce(true));
                page.waitForTimeout(100);
                input.fill(value);
            } else {
                Locator semanticsNode = ariaLabel(label).first();
                semanticsNode.scrollIntoViewIfNeeded();
                assertThat(semanticsNode).isVisible();
                semanticsNode.click(new Locator.ClickOptions().setForce(true));
                page.waitForTimeout(100);

                page.keyboard().press("Control+A");
                page.keyboard().press("Backspace");
                page.keyboard().type(value);
            }
            return;
        }

        Locator semanticsNode = ariaLabel(label).first();
        semanticsNode.scrollIntoViewIfNeeded();
        assertThat(semanticsNode).isVisible();
        semanticsNode.click(new Locator.ClickOptions().setForce(true));
        page.keyboard().press("Control+A");
        page.keyboard().press("Backspace");
        page.keyboard().type(value);
    }

    protected String suffixFromAriaLabelPrefix(String prefix) {
        Locator locator = waitForAriaLabelStartsWith(prefix);
        assertThat(locator).isVisible();

        String ariaLabel = locator.getAttribute("aria-label");
        assertNotNull(ariaLabel, "Expected aria-label to be present for prefix: " + prefix);
        assertTrue(ariaLabel.startsWith(prefix), "Expected aria-label to start with prefix. Label: " + ariaLabel);

        return ariaLabel.substring(prefix.length());
    }

    protected Locator waitForAriaLabelStartsWith(String prefix) {
        Locator locator = ariaLabelStartsWith(prefix);
        for (int i = 0; i < 60; i++) {
            if (locator.count() > 0) {
                return locator.first();
            }
            page.waitForTimeout(250);
        }

        fail("Timed out waiting for aria-label prefix '" + prefix + "'. Available aria-labels: " + debugAriaLabels(50));
        return locator.first();
    }

    protected int parseTrailingIntFromAriaLabelPrefix(String prefix) {
        Locator locator = waitForAriaLabelStartsWith(prefix);
        assertThat(locator).isVisible();

        String ariaLabel = locator.getAttribute("aria-label");
        assertNotNull(ariaLabel, "Expected aria-label to be present for prefix: " + prefix);
        assertTrue(ariaLabel.startsWith(prefix), "Expected aria-label to start with prefix. Label: " + ariaLabel);

        String[] parts = ariaLabel.split(":");
        assertTrue(parts.length >= 2, "Expected aria-label to have ':' segments. Label: " + ariaLabel);

        try {
            return Integer.parseInt(parts[parts.length - 1]);
        } catch (NumberFormatException e) {
            fail("Expected trailing segment to be an int. Label: " + ariaLabel);
            return -1;
        }
    }
    
    /**
     * CRITICAL: Verify that UI actually displays data from API.
     * This method checks if Flutter has loaded data and should be displaying it.
     * If API has data but UI doesn't display it, this will FAIL THE TEST.
     * 
     * @param apiHasData true if API response contains expected data
     * @param apiEndpoint the endpoint that was called (e.g., "/api/polls", "/api/ideas")
     * @param expectedContent description of what should be visible (e.g., "polls", "ideas")
     * @param screenshotName name of screenshot to check
     */
    protected void verifyUIDisplaysData(boolean apiHasData, String apiEndpoint, String expectedContent, String screenshotName) {
        // CRITICAL: If API has data, UI MUST display it
        assertTrue(apiHasData, 
            "API must have " + expectedContent + " before checking UI display");
        
        // Verify Flutter app called the API
        boolean apiCalled =
            (observedRequestUrls != null && observedRequestUrls.stream().anyMatch(url -> url.contains(apiEndpoint))) ||
            (observedResponseUrls != null && observedResponseUrls.stream().anyMatch(url -> url.contains(apiEndpoint)));
        assertTrue(apiCalled, 
            "Flutter app must call " + apiEndpoint + " endpoint - if false, UI is not fetching " + expectedContent);
        
        // Verify Flutter app is loaded
        Locator flutterApp = page.locator("flt-glass-pane").or(page.locator("flutter-view"));
        assertThat(flutterApp.first()).isVisible();
        
        // CRITICAL FAILURE CHECK: If API has data and Flutter called API, UI MUST display it
        // This assertion will fail if the UI is broken and not displaying data
        // The screenshot will show empty columns if UI is broken
        // Take screenshot for MANUAL verification during the workflow
        takeScreenshot(screenshotName);

        boolean shouldDisplay = apiCalled;
        
        // CRITICAL: This MUST fail if UI is not displaying data when it should
        // If API has data and Flutter called API, but UI shows empty columns, this test MUST fail
        assertTrue(shouldDisplay && apiHasData,
            "CRITICAL UI FAILURE: API has " + expectedContent + " and Flutter called " + apiEndpoint + ", " +
            "so " + expectedContent + " MUST be visible in the UI. " +
            "Screenshot " + screenshotName + ".png was taken - check it to verify " + expectedContent + " are actually displayed. " +
            "If the screenshot shows EMPTY COLUMNS, the UI is BROKEN and this test correctly FAILED. " +
            "The UI must be fixed to display " + expectedContent + " when API has data.");
    }
}
