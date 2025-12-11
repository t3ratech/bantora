package com.t3ratech.bantora.ui;

import com.microsoft.playwright.*;
import com.t3ratech.bantora.ui.config.PlaywrightTestConfig;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.nio.file.Paths;

@SpringBootTest(classes = PlaywrightTestConfig.class)
@ActiveProfiles("test")
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
public abstract class BasePlaywrightTest {

    protected static Playwright playwright;
    protected static Browser browser;
    protected BrowserContext context;
    protected Page page;

    @BeforeAll
    static void launchBrowser() {
        playwright = Playwright.create();
        browser = playwright.chromium().launch(new BrowserType.LaunchOptions().setHeadless(true));
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
    }

    protected void takeScreenshot(String name) {
        page.screenshot(new Page.ScreenshotOptions()
                .setPath(Paths.get("test-results/screenshots/" + name + ".png"))
                .setFullPage(true));
    }
}
