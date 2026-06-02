-- Habilitar extensión UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. TABLA: profiles
CREATE TABLE public.profiles (
    id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Habilitar RLS en profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Los usuarios pueden ver su propio perfil" 
ON public.profiles FOR SELECT 
USING (auth.uid() = id);

CREATE POLICY "Los usuarios pueden actualizar su propio perfil" 
ON public.profiles FOR UPDATE 
USING (auth.uid() = id);

-- 2. TABLA: families
CREATE TABLE public.families (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    invite_code TEXT UNIQUE NOT NULL,
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    admin_user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    deleted BOOLEAN DEFAULT false NOT NULL,
    deleted_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    deleted_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Habilitar RLS en families
ALTER TABLE public.families ENABLE ROW LEVEL SECURITY;

-- 3. TABLA: family_members
CREATE TABLE public.family_members (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    family_id UUID REFERENCES public.families(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('admin', 'member')),
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    UNIQUE (family_id, user_id)
);

-- Habilitar RLS en family_members
ALTER TABLE public.family_members ENABLE ROW LEVEL SECURITY;

-- Policies for families and members
CREATE POLICY "Usuarios pueden ver familias de las que son miembros"
ON public.families FOR SELECT
USING (EXISTS (
    SELECT 1 FROM public.family_members 
    WHERE family_members.family_id = id AND family_members.user_id = auth.uid()
));

CREATE POLICY "Usuarios pueden actualizar familias si son admins"
ON public.families FOR UPDATE
USING (auth.uid() = admin_user_id);

CREATE POLICY "Cualquier usuario autenticado puede crear familias"
ON public.families FOR INSERT
WITH CHECK (auth.uid() = created_by OR auth.uid() = admin_user_id);

CREATE POLICY "Miembros pueden ver miembros de su familia"
ON public.family_members FOR SELECT
USING (EXISTS (
    SELECT 1 FROM public.family_members AS fm
    WHERE fm.family_id = family_id AND fm.user_id = auth.uid()
));

CREATE POLICY "Admins pueden agregar/modificar miembros"
ON public.family_members FOR ALL
USING (EXISTS (
    SELECT 1 FROM public.families 
    WHERE families.id = family_id AND families.admin_user_id = auth.uid()
) OR auth.uid() = user_id); -- Un usuario puede salirse a sí mismo

-- 4. TABLA: transactions (Modificada para incluir familias, auditoría y soft-delete)
CREATE TYPE transaction_type_enum AS ENUM ('gasto', 'abono');
CREATE TYPE target_module_enum AS ENUM ('personal', 'casa');

CREATE TABLE public.transactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    concept TEXT NOT NULL,
    category TEXT NOT NULL,
    transaction_type transaction_type_enum NOT NULL,
    target_module target_module_enum NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    
    -- Nuevos campos para evolución
    family_id UUID REFERENCES public.families(id) ON DELETE CASCADE,
    updated_by UUID REFERENCES public.profiles(id),
    deleted BOOLEAN DEFAULT false NOT NULL,
    deleted_by UUID REFERENCES public.profiles(id),
    deleted_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Habilitar RLS en transactions
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuarios pueden ver sus transacciones personales o las de sus familias"
ON public.transactions FOR SELECT
USING (
    (target_module = 'personal' AND user_id = auth.uid()) OR
    (target_module = 'casa' AND family_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM public.family_members 
        WHERE family_members.family_id = transactions.family_id AND family_members.user_id = auth.uid()
    ))
);

CREATE POLICY "Usuarios pueden insertar transacciones"
ON public.transactions FOR INSERT
WITH CHECK (
    user_id = auth.uid() AND
    (
        target_module = 'personal' OR
        (target_module = 'casa' AND family_id IS NOT NULL AND EXISTS (
            SELECT 1 FROM public.family_members 
            WHERE family_members.family_id = transactions.family_id AND family_members.user_id = auth.uid()
        ))
    )
);

CREATE POLICY "Usuarios pueden actualizar transacciones"
ON public.transactions FOR UPDATE
USING (
    (target_module = 'personal' AND user_id = auth.uid()) OR
    (target_module = 'casa' AND family_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM public.family_members 
        WHERE family_members.family_id = transactions.family_id AND family_members.user_id = auth.uid()
    ))
);

CREATE POLICY "Usuarios pueden eliminar transacciones (para hard delete, aunque usaremos soft)"
ON public.transactions FOR DELETE
USING (
    (target_module = 'personal' AND user_id = auth.uid()) OR
    (target_module = 'casa' AND family_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM public.family_members 
        WHERE family_members.family_id = transactions.family_id AND family_members.user_id = auth.uid()
    ))
);

-- 5. TABLA: budgets
CREATE TABLE public.budgets (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    limit_amount NUMERIC(12, 2) NOT NULL CHECK (limit_amount >= 0),
    month_year TEXT NOT NULL -- Formato 'MM-YYYY'
);

-- Habilitar RLS en budgets
ALTER TABLE public.budgets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Los usuarios pueden manejar sus propios presupuestos" 
ON public.budgets FOR ALL 
USING (auth.uid() = user_id);

-- 6. TABLA: transaction_audits
CREATE TABLE public.transaction_audits (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    transaction_id UUID NOT NULL,
    family_id UUID REFERENCES public.families(id) ON DELETE CASCADE NOT NULL,
    action TEXT NOT NULL CHECK (action IN ('created', 'updated', 'deleted', 'family_deleted')),
    performed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL NOT NULL,
    previous_data JSONB,
    new_data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

ALTER TABLE public.transaction_audits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Miembros pueden ver la auditoria de su familia"
ON public.transaction_audits FOR SELECT
USING (EXISTS (
    SELECT 1 FROM public.family_members 
    WHERE family_members.family_id = transaction_audits.family_id AND family_members.user_id = auth.uid()
));

CREATE POLICY "Permitir insercion de auditoria a miembros"
ON public.transaction_audits FOR INSERT
WITH CHECK (EXISTS (
    SELECT 1 FROM public.family_members 
    WHERE family_members.family_id = transaction_audits.family_id AND family_members.user_id = auth.uid()
));

-- 7. TABLA: notifications
CREATE TABLE public.notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    family_id UUID REFERENCES public.families(id) ON DELETE CASCADE NOT NULL,
    recipient_user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    triggered_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('transaction_created', 'transaction_updated', 'transaction_deleted', 'family_deleted', 'code_regenerated')),
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    read BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuarios pueden manejar sus propias notificaciones"
ON public.notifications FOR ALL
USING (auth.uid() = recipient_user_id);

-- 8. TABLA: email_detected_movements
CREATE TABLE public.email_detected_movements (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    provider TEXT DEFAULT 'gmail' NOT NULL,
    bank TEXT DEFAULT 'BCP' NOT NULL,
    email_message_id TEXT UNIQUE NOT NULL,
    detected_amount NUMERIC(12, 2) NOT NULL CHECK (detected_amount > 0),
    detected_date TIMESTAMP WITH TIME ZONE NOT NULL,
    detected_concept TEXT NOT NULL,
    detected_currency TEXT DEFAULT 'PEN' NOT NULL,
    detected_type TEXT NOT NULL CHECK (detected_type IN ('expense', 'income', 'unknown')),
    suggested_category TEXT NOT NULL,
    status TEXT DEFAULT 'pending' NOT NULL CHECK (status IN ('pending', 'approved', 'ignored')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

ALTER TABLE public.email_detected_movements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuarios pueden manejar sus propios movimientos detectados"
ON public.email_detected_movements FOR ALL
USING (auth.uid() = user_id);

-- 9. TABLA: category_learning_rules
CREATE TABLE public.category_learning_rules (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    keyword TEXT UNIQUE NOT NULL,
    suggested_category TEXT NOT NULL,
    suggested_scope TEXT CHECK (suggested_scope IN ('personal', 'family')),
    suggested_family_id UUID REFERENCES public.families(id) ON DELETE CASCADE,
    confidence INTEGER DEFAULT 1 NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

ALTER TABLE public.category_learning_rules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuarios pueden manejar sus propias reglas de aprendizaje"
ON public.category_learning_rules FOR ALL
USING (auth.uid() = user_id);

-- TRIGGER AUTOMÁTICO: Crear perfil en profiles al registrarse en auth.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name)
    VALUES (
        new.id,
        new.email,
        coalesce(new.raw_user_meta_data->>'full_name', '')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
