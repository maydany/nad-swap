import { Navigate, RouterProvider, createBrowserRouter } from "react-router-dom";

import { AppShell } from "./AppShell";
import { APP_ROUTES } from "./nav";
import { AdminPage } from "../pages/AdminPage";
import { LensPage } from "../pages/LensPage";
import { PoolsPage } from "../pages/PoolsPage";
import { SwapPage } from "../pages/SwapPage";

const router = createBrowserRouter([
  {
    path: "/",
    element: <AppShell />,
    children: [
      {
        index: true,
        element: <Navigate to={APP_ROUTES.swap} replace />
      },
      {
        path: APP_ROUTES.swap,
        element: <SwapPage />
      },
      {
        path: APP_ROUTES.pools,
        element: <PoolsPage />
      },
      {
        path: APP_ROUTES.lens,
        element: <LensPage />
      },
      {
        path: APP_ROUTES.admin,
        element: <AdminPage />
      },
      {
        path: "*",
        element: <Navigate to={APP_ROUTES.swap} replace />
      }
    ]
  }
]);

export const AppRouter = () => <RouterProvider router={router} />;
