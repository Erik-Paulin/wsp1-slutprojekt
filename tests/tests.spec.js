import { test, expect } from '@playwright/test';

test.describe('Sinatra App Tests', () => {
  const baseUrl = 'http://localhost:9292';

  test('Home page loads with meds and ills', async ({ page }) => {
    await page.goto(`${baseUrl}/index`);
    await expect(page).toHaveTitle(/Mediciner och sjukdommar/); 
    await expect(page.getByTestId('1')).toContainText('Mediciner'); 
    await expect(page.getByTestId('2')).toContainText('Sjukdomar'); 
  });

  test('Login page is accessible', async ({ page }) => {
    await page.goto(`${baseUrl}/login`);
    await expect(page.locator('form')).toBeVisible();
    await expect(page.locator('input[name="username"]')).toBeVisible();
    await expect(page.locator('input[name="password"]')).toBeVisible();
  });

  test('User can log in with valid credentials', async ({ page }) => {
    await page.goto(`${baseUrl}/login`);
    await page.fill('input[name="username"]', 'user');
    await page.fill('input[name="password"]', 'user'); 
    await page.click('button[type="submit"]');
    await expect(page).toHaveURL(`${baseUrl}/index`);
  });

  test('Unauthorized page redirects properly', async ({ page }) => {
    await page.goto(`${baseUrl}/unauthorized`);
    await expect(page.locator('h1')).toContainText('Unauthorized');
  });

  test('Admin protected route redirects unauthorized users', async ({ page }) => {
    await page.goto(`${baseUrl}/admin/meds/new_med`);
    await expect(page).toHaveURL(`${baseUrl}/unauthorized`);
  });

  test('Admin can create a new medicine', async ({ page }) => {
    await page.goto(`${baseUrl}/login`);
    await page.fill('input[name="username"]', 'admin');
    await page.fill('input[name="password"]', 'admin');
    await page.click('button[type="submit"]');

    await page.goto(`${baseUrl}/admin/meds/new_med`);
    await expect(page.locator('form')).toBeVisible(); 
  
    await page.fill('input[name="med_name"]', 'Test Medicine');
    await page.fill('textarea[name="med_desc"]', 'This is a test medicine.');
    await page.click('input[type="submit"]');
  
    await expect(page).toHaveURL(`${baseUrl}/index`);
  });

  test('Medicine details page shows correct information', async ({ page }) => {
    await page.goto(`${baseUrl}/meds/show_med/2`); 
    await expect(page.locator('h1')).toBeVisible(); 
  });

  test('Admin can edit an existing illness', async ({ page }) => {
    await page.goto(`${baseUrl}/login`);
    await page.fill('input[name="username"]', 'admin'); 
    await page.fill('input[name="password"]', 'admin'); 
    await page.click('button[type="submit"]');

    await page.goto(`${baseUrl}/admin/ills/1/edit_ill`); 
    await page.fill('input[name="ill_name"]', 'Updated Illness Name');
    await page.fill('textarea[name="ill_desc"]', 'Updated illness description.');
    await page.click('input[type="submit"]');
    await expect(page).toHaveURL(`${baseUrl}/index`);
  });

  test('Admin can delete a medicine', async ({ page }) => {
    await page.goto(`${baseUrl}/login`);
    await page.fill('input[name="username"]', 'admin'); 
    await page.fill('input[name="password"]', 'admin');
    await page.click('button[type="submit"]');

    await page.request.post(`${baseUrl}/admin/meds/remove_med/1/delete`);
    await expect(page).toHaveURL(`${baseUrl}/index`);
  });
});